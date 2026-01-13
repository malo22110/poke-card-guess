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
  cards: GameCard[]; // Pre-fetched cards for the game
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
        sets: config.sets || ['all'],
        secretOnly: config.secretOnly || false,
      },
      status: 'WAITING',
      currentRound: 0,
      cards: [],
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

  // --- Game Logic ---

  async startGame(lobbyId: string, userId: string) {
    const lobby = this.lobbies.get(lobbyId);
    if (!lobby)
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);

    // If game is already playing, just return the current round (Join in progress)
    if (lobby.status === 'PLAYING') {
      return this.getCurrentRoundData(lobby);
    }

    // Only host can actually START the game from WAITING state
    if (lobby.hostId !== userId) {
      return { status: 'WAITING', message: 'Waiting for host to start...' };
    }

    // Fetch cards based on config
    lobby.cards = await this.fetchGameCards(lobby.config);
    lobby.status = 'PLAYING';
    lobby.currentRound = 1;

    return this.getCurrentRoundData(lobby);
  }

  getCurrentRoundData(lobby: GameLobby) {
    if (lobby.currentRound > lobby.cards.length) {
      lobby.status = 'FINISHED';
      return { status: 'FINISHED' };
    }
    const card = lobby.cards[lobby.currentRound - 1];
    return {
      gameId: lobby.id,
      round: lobby.currentRound,
      totalRounds: lobby.config.rounds,
      croppedImage: `data:image/png;base64,${card.croppedImage}`,
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

    // Check guess
    const isCorrect =
      normalizedActual.includes(normalizedGuess) && normalizedGuess.length >= 3;

    if (isCorrect) {
      // Logic for scoring would go here (update user score in lobby)

      const result = {
        correct: true,
        name: currentCard.name,
        fullImageUrl: currentCard.fullImageUrl,
        set: currentCard.set,
      };

      // Advance round
      lobby.currentRound++;

      // Save result to DB (History)
      await this.saveRoundResult(userId, currentCard, true);

      return result;
    } else {
      return { correct: false };
    }
  }

  // --- Helpers ---

  private async fetchGameCards(config: GameConfig): Promise<GameCard[]> {
    const cards: GameCard[] = [];
    // Currently fetching random cards one by one.
    // Optimization: Fetch a pool of cards matching criteria.

    // For now, implementing simple loop until we get enough valid cards
    let attempts = 0;
    while (cards.length < config.rounds && attempts < config.rounds * 3) {
      attempts++;
      try {
        const cardData = await this.fetchRandomCardRaw(); // Helper to get a single random card
        if (!cardData) continue;

        // TODO: Apply filters (Sets, Secret Rare) here
        // If config.sets is not 'all', check if card.set.id is in config.sets

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

  private async fetchRandomCardRaw() {
    const sets = await this.tcgdex.fetch('sets');
    if (!sets || sets.length === 0) return null;

    const randomSetSummary = sets[Math.floor(Math.random() * sets.length)];
    if (!randomSetSummary) return null;

    const setDetails = await this.tcgdex.fetch('sets', randomSetSummary.id);
    if (!setDetails || !setDetails.cards || setDetails.cards.length === 0)
      return null;

    const randomCardResume =
      setDetails.cards[Math.floor(Math.random() * setDetails.cards.length)];
    if (!randomCardResume) return null;

    const card = await this.tcgdex.fetch('cards', randomCardResume.id);
    if (!card || !card.image) return null;

    return card;
  }

  // --- Legacy / Database Logic ---

  async saveRoundResult(userId: string, card: GameCard, correct: boolean) {
    // Keeping legacy prisma write for user stats
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

    // Crop bottom 30%
    const cropHeight = Math.floor(metadata.height * 0.3);
    const top = metadata.height - cropHeight;

    const croppedBuffer = await image
      .extract({ left: 0, top: top, width: metadata.width, height: cropHeight })
      .toBuffer();

    return croppedBuffer.toString('base64');
  }
}
