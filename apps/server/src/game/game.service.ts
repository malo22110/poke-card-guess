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
      },
      status: 'WAITING',
      currentRound: 0,
      cards: [],
      roundResults: new Map(),
      scores: new Map([[hostId, 0]]), // Initialize host score
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
    lobby.roundResults.clear();

    return this.getCurrentRoundData(lobby);
  }

  getCurrentRoundData(lobby: GameLobby) {
    if (lobby.currentRound > lobby.cards.length) {
      lobby.status = 'FINISHED';
      return {
        status: 'FINISHED',
        scores: Object.fromEntries(lobby.scores),
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

      // Increment score
      const currentScore = lobby.scores.get(userId) || 0;
      lobby.scores.set(userId, currentScore + 1);

      await this.saveRoundResult(userId, currentCard, true);

      const allFinished = lobby.players.every((p) => lobby.roundResults.get(p));

      const result = {
        correct: true,
        name: currentCard.name,
        fullImageUrl: currentCard.fullImageUrl,
        set: currentCard.set,
        roundFinished: allFinished,
      };

      if (allFinished) {
        lobby.currentRound++;
        lobby.roundResults.clear();
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

    while (cards.length < config.rounds && attempts < maxAttempts) {
      attempts++;
      try {
        const cardData = await this.fetchRandomCardRaw(config.sets);
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
    const cropHeight = Math.floor(metadata.height * 0.3);
    const top = metadata.height - cropHeight;
    const croppedBuffer = await image
      .extract({ left: 0, top: top, width: metadata.width, height: cropHeight })
      .toBuffer();
    return croppedBuffer.toString('base64');
  }
}
