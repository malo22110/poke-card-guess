import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import TCGdex from '@tcgdex/sdk';
import axios from 'axios';
import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../prisma.service';

export interface GameConfig {
  rounds: number;
  sets: string[]; // ['all'] or specific set IDs
  secretOnly: boolean;
  rarities?: string[]; // Optional custom rarities list
}

export interface CardSummary {
  id: string;
  localId: string;
  name: string;
  image: string;
}

export interface GameLobby {
  id: string;
  hostId: string;
  players: string[]; // User IDs
  config: GameConfig;
  status: 'WAITING' | 'PLAYING' | 'FINISHED';
  currentRound: number;
  cards: GameCard[];
  roundResults: Map<string, boolean>; // userId -> hasFinishedRound
  scores: Map<string, number>; // userId -> total score
  roundStartTime: number;
  timer?: any; // NodeJS.Timeout
}

export interface GameCard {
  id: string;
  name: string;
  fullImageUrl: string;
  set: string;
  croppedImage: string; // Base64
}

@Injectable()
export class GameService {
  private readonly tcgdex = new TCGdex('fr');

  // In-memory storage for lobbies
  private lobbies = new Map<string, GameLobby>();

  // Cache for special rarities to avoid fetching on every game
  private specialRaritiesCache: string[] | null = null;

  constructor(private prisma: PrismaService) {}

  // --- Lobby Management ---

  createLobby(hostId: string, config: Partial<GameConfig> = {}): GameLobby {
    const lobbyId = uuidv4().substring(0, 8).toUpperCase(); // Short ID for easier joining
    const newLobby: GameLobby = {
      id: lobbyId,
      hostId,
      players: [hostId],
      config: {
        rounds: config.rounds || 10,
        sets: config.sets || ['151'],
        secretOnly: config.secretOnly || true,
        rarities: config.rarities,
      },
      status: 'WAITING',
      currentRound: 0,
      cards: [],
      roundResults: new Map(),
      scores: new Map([[hostId, 0]]), // Initialize host score
      roundStartTime: 0,
    };

    this.lobbies.set(lobbyId, newLobby);
    return newLobby;
  }

  joinLobby(userId: string, lobbyId: string): GameLobby {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby) {
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);
    }
    if (lobby.status !== 'WAITING') {
      throw new HttpException('Game already started', HttpStatus.BAD_REQUEST);
    }
    if (!lobby.players.includes(userId)) {
      lobby.players.push(userId);
      lobby.scores.set(userId, 0); // Initialize score
    }
    return lobby;
  }

  getLobby(lobbyId: string): GameLobby {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby) {
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);
    }
    return lobby;
  }

  getLobbyStatus(lobbyId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby) {
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);
    }
    return {
      status: lobby.status,
      players: lobby.players.length,
      hostId: lobby.hostId,
      config: lobby.config,
      scores: Object.fromEntries(lobby.scores), // Convert Map to object
    };
  }

  // --- Game Logic ---

  async startGame(lobbyId: string, userId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby)
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);

    if (lobby.status === 'PLAYING') {
      return this.getCurrentRoundData(lobby);
    }

    if (lobby.hostId !== userId) {
      return { status: 'WAITING', message: 'Waiting for host to start...' };
    }

    lobby.cards = await this.fetchGameCards(lobby.config);
    lobby.status = 'PLAYING';
    lobby.currentRound = 1;
    lobby.roundStartTime = Date.now();
    lobby.roundResults.clear();

    return this.getCurrentRoundData(lobby);
  }

  getCurrentRoundData(lobby: GameLobby) {
    if (lobby.currentRound > lobby.cards.length) {
      lobby.status = 'FINISHED';
      const finalScores = Object.fromEntries(lobby.scores);
      console.log(`[Game Finished] Final scores:`, finalScores);
      return {
        status: 'FINISHED',
        scores: finalScores,
        history: lobby.cards.map((card) => ({
          name: card.name,
          fullImageUrl: card.fullImageUrl,
          set: card.set,
        })),
      };
    }
    const card = lobby.cards[lobby.currentRound - 1];
    return {
      gameId: lobby.id,
      round: lobby.currentRound,
      totalRounds: lobby.config.rounds,
      croppedImage: `data:image/png;base64,${card.croppedImage}`,
      scores: Object.fromEntries(lobby.scores),
      status: lobby.status,
    };
  }

  async makeGuess(lobbyId: string, userId: string, guess: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby || lobby.status !== 'PLAYING') {
      throw new HttpException('Game not active', HttpStatus.BAD_REQUEST);
    }

    const currentCard = lobby.cards[lobby.currentRound - 1];
    const normalizedGuess = guess.trim().toLowerCase();
    const normalizedActual = currentCard.name.toLowerCase();

    const isCorrect =
      normalizedActual.includes(normalizedGuess) && normalizedGuess.length >= 3;

    if (isCorrect) {
      lobby.roundResults.set(userId, true);

      // Calculate score based on time taken (points = remaining milliseconds of 30s round)
      const elapsedTime = Math.max(
        0,
        Date.now() - (lobby.roundStartTime || Date.now()),
      );
      const roundScore = Math.max(0, 30000 - elapsedTime);

      const currentScore = lobby.scores.get(userId) || 0;
      lobby.scores.set(userId, currentScore + roundScore);

      console.log(
        `[Score Update] User ${userId} scored ${roundScore} points! New total: ${currentScore + roundScore}`,
      );
      console.log(
        `[Round Info] Current round: ${lobby.currentRound}/${lobby.config.rounds}`,
      );

      await this.saveRoundResult(userId, currentCard, true);

      const allFinished = lobby.players.every((p) => lobby.roundResults.get(p));

      const result = {
        correct: true,
        name: currentCard.name,
        fullImageUrl: currentCard.fullImageUrl,
        set: currentCard.set,
        roundFinished: allFinished,
        scores: Object.fromEntries(lobby.scores), // Include current scores
        currentRound: lobby.currentRound,
        totalRounds: lobby.config.rounds,
      };

      if (allFinished) {
        console.log(
          `[Round Complete] All players finished round ${lobby.currentRound}`,
        );
        console.log(
          `[Scores] Current scores:`,
          Object.fromEntries(lobby.scores),
        );
        lobby.currentRound++;
        lobby.roundStartTime = Date.now();
        lobby.roundResults.clear();
        console.log(`[Round Advance] Advanced to round ${lobby.currentRound}`);
      }

      return result;
    } else {
      return { correct: false };
    }
  }

  async giveUp(lobbyId: string, userId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby || lobby.status !== 'PLAYING') {
      throw new HttpException('Game not active', HttpStatus.BAD_REQUEST);
    }

    const currentCard = lobby.cards[lobby.currentRound - 1];
    lobby.roundResults.set(userId, true);
    await this.saveRoundResult(userId, currentCard, false);

    const allFinished = lobby.players.every((p) => lobby.roundResults.get(p));

    const result = {
      name: currentCard.name,
      fullImageUrl: currentCard.fullImageUrl,
      set: currentCard.set,
      roundFinished: allFinished,
    };

    if (allFinished) {
      lobby.currentRound++;
      lobby.roundStartTime = Date.now();
      lobby.roundResults.clear();
    }

    return result;
  }

  async forceEndRound(lobbyId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby || lobby.status !== 'PLAYING') return null;

    const currentCard = lobby.cards[lobby.currentRound - 1];

    // Mark all remaining players as finished (incorrect)
    for (const userId of lobby.players) {
      if (!lobby.roundResults.has(userId)) {
        lobby.roundResults.set(userId, true);
        await this.saveRoundResult(userId, currentCard, false);
      }
    }

    // Advance round
    lobby.currentRound++;
    lobby.roundStartTime = Date.now();
    lobby.roundResults.clear();

    return {
      name: currentCard.name,
      fullImageUrl: currentCard.fullImageUrl,
      set: currentCard.set,
      roundFinished: true,
    };
  }

  setRoundTimer(lobbyId: string, callback: () => void, ms: number) {
    const lobby = this.lobbies.get(lobbyId);
    if (lobby) {
      if (lobby.timer) clearTimeout(lobby.timer);
      lobby.timer = setTimeout(callback, ms);
    }
  }

  clearRoundTimer(lobbyId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (lobby && lobby.timer) {
      clearTimeout(lobby.timer);
      lobby.timer = undefined;
    }
  }

  // --- Helpers ---

  private async fetchGameCards(config: GameConfig): Promise<GameCard[]> {
    const cards: GameCard[] = [];
    let attempts = 0;
    const maxAttempts = config.rounds * 5;

    // If secretOnly is enabled, fetch all secret rare cards first
    let availableCards: CardSummary[] = [];
    if (config.secretOnly) {
      try {
        availableCards = await this.fetchSecretRareCards(
          config.sets,
          config.rarities,
        );
        console.log(`Found ${availableCards.length} secret rare cards`);
      } catch (e) {
        console.error('Failed to fetch secret rare cards', e);
        return cards;
      }
    }

    while (cards.length < config.rounds && attempts < maxAttempts) {
      attempts++;
      try {
        let cardData;

        if (config.secretOnly && availableCards.length > 0) {
          // Pick a random card from the pre-fetched secret rare cards
          const randomIndex = Math.floor(Math.random() * availableCards.length);
          const cardSummary = availableCards[randomIndex];

          // Remove it from the available pool to avoid duplicates
          availableCards.splice(randomIndex, 1);

          // Fetch full card details
          cardData = await this.tcgdex.fetch('cards', cardSummary.id);
        } else {
          // Use the old method for non-secret cards
          cardData = await this.fetchRandomCardRaw(config.sets);
        }

        if (!cardData) continue;
        if (cards.some((c) => c.id === cardData.id)) continue;

        const imageBuffer = await this.downloadImage(
          `${cardData.image}/high.png`,
        );
        const croppedImage = await this.cropImage(imageBuffer);

        cards.push({
          id: cardData.id,
          name: cardData.name,
          fullImageUrl: `${cardData.image}/high.png`,
          set: cardData.set.name,
          croppedImage,
        });
      } catch (e) {
        console.warn('Failed to fetch/process a card', e);
      }
    }
    return cards;
  }

  private async fetchRandomCardRaw(allowedSets: string[] = ['all']) {
    let setId: string;
    if (allowedSets.length > 0 && !allowedSets.includes('all')) {
      setId = allowedSets[Math.floor(Math.random() * allowedSets.length)];
    } else {
      const sets = await this.tcgdex.fetch('sets');
      if (!sets || sets.length === 0) return null;
      const randomSetSummary = sets[Math.floor(Math.random() * sets.length)];
      if (!randomSetSummary) return null;
      setId = randomSetSummary.id;
    }

    const setDetails = await this.tcgdex.fetch('sets', setId);
    if (!setDetails || !setDetails.cards || setDetails.cards.length === 0)
      return null;

    const randomCardResume =
      setDetails.cards[Math.floor(Math.random() * setDetails.cards.length)];
    if (!randomCardResume) return null;

    const card = await this.tcgdex.fetch('cards', randomCardResume.id);
    if (!card || !card.image) return null;
    return card;
  }

  private async fetchSecretRareCards(
    allowedSets: string[] = ['all'],
    customRarities?: string[],
  ): Promise<CardSummary[]> {
    try {
      // Use custom rarities if provided, otherwise use cached/fetched special rarities
      let specialRarities: string[];

      if (customRarities && customRarities.length > 0) {
        // Use the custom rarities provided by the user
        specialRarities = customRarities;
        console.log(`Using custom rarities: ${specialRarities.join(', ')}`);
      } else if (this.specialRaritiesCache) {
        specialRarities = this.specialRaritiesCache;
        console.log('Using cached special rarities');
      } else {
        // First, fetch all available rarities
        const raritiesUrl = 'https://api.tcgdex.net/v2/fr/rarities';
        const raritiesResponse = await axios.get<string[]>(raritiesUrl);
        const allRarities = raritiesResponse.data;

        // Define rarities to EXCLUDE (common/basic rarities)
        const excludedRarities = [
          'Commune', // Common
          'Peu Commune', // Uncommon
          'Rare', // Rare
          'Rare Holo', // Rare Holo
          'Holo Rare', // Holo Rare
          'Sans Rareté', // None
          'Un Diamant', // One Diamond
          'Deux Diamants', // Two Diamonds
          'Trois Diamants', // Three Diamonds
          'Quatre Diamants', // Four Diamonds
          'Une Étoile', // One Star
          'Deux Étoiles', // Two Stars
          'Trois Étoiles', // Three Stars
          'Couronne', // Crown
          'Double rare',
        ];

        // Filter to get only special/ultra rare cards
        specialRarities = allRarities.filter(
          (rarity) => !excludedRarities.includes(rarity),
        );

        // Cache the result
        this.specialRaritiesCache = specialRarities;
        console.log(
          `Fetched and cached special rarities: ${specialRarities.join(', ')}`,
        );
      }

      console.log(`Using special rarities: ${specialRarities.join(', ')}`);

      // Fetch cards for each special rarity
      const allCards: CardSummary[] = [];
      const baseUrl = 'https://api.tcgdex.net/v2/fr/cards';

      for (const rarity of specialRarities) {
        let url = `${baseUrl}?rarity=eq:${encodeURIComponent(rarity)}`;

        // If specific sets are requested, filter by set as well
        if (allowedSets.length > 0 && !allowedSets.includes('all')) {
          const setsFilter = allowedSets.join('|');
          url += `&set.id=${setsFilter}`;
        }

        try {
          const response = await axios.get<CardSummary[]>(url);
          const cards = response.data;

          if (Array.isArray(cards)) {
            allCards.push(...cards);
            console.log(`Fetched ${cards.length} cards with rarity: ${rarity}`);
          }
        } catch (error) {
          console.warn(`Failed to fetch cards for rarity ${rarity}:`, error);
        }
      }

      console.log(
        `Successfully fetched ${allCards.length} total special rare cards`,
      );
      return allCards;
    } catch (error) {
      console.error('Error fetching secret rare cards:', error);
      throw error;
    }
  }

  async getAvailableSets() {
    const sets = await this.tcgdex.fetch('sets');
    if (!sets) return [];
    return sets.map((s) => ({
      id: s.id,
      name: s.name,
      logo: s.logo,
      symbol: s.symbol,
      cardCount: s.cardCount,
    }));
  }

  async getAvailableRarities() {
    try {
      const raritiesUrl = 'https://api.tcgdex.net/v2/fr/rarities';
      const response = await axios.get<string[]>(raritiesUrl);
      return response.data;
    } catch (error) {
      console.error('Error fetching rarities:', error);
      return [];
    }
  }

  async saveRoundResult(userId: string, card: GameCard, correct: boolean) {
    if (userId.startsWith('guest')) return;

    await this.prisma.game.create({
      data: {
        userId,
        cardName: card.name,
        cardSet: card.set,
        correct,
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        totalAttempts: { increment: 1 },
        totalScore: { increment: correct ? 1 : 0 },
      },
    });
  }

  private async downloadImage(url: string): Promise<Buffer> {
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    return Buffer.from(response.data);
  }

  private async cropImage(buffer: Buffer): Promise<string> {
    const image = sharp(buffer);
    const metadata = await image.metadata();
    if (!metadata.width || !metadata.height) {
      throw new Error('Could not get image metadata');
    }
    const cropHeight = Math.floor(metadata.height * 0.1);
    const top = metadata.height - cropHeight;
    const croppedBuffer = await image
      .extract({ left: 0, top: top, width: metadata.width, height: cropHeight })
      .toBuffer();
    return croppedBuffer.toString('base64');
  }
}
