import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import TCGdex from '@tcgdex/sdk';
import axios from 'axios';
import sharp from 'sharp';
import { v4 as uuidv4 } from 'uuid';

interface GameSession {
  cardId: string;
  name: string;
  fullImageUrl: string;
  set: string;
}

@Injectable()
export class GameService {
  private readonly tcgdex = new TCGdex('fr');
  // In-memory storage for active games (Not production ready for scaling, but fine for MVP)
  private activeGames = new Map<string, GameSession>();

  async startGame() {
    try {
      // 1. Fetch random card logic (reused)
      const sets = await this.tcgdex.fetch('sets');
      if (!sets || sets.length === 0)
        throw new HttpException('No sets found', HttpStatus.NOT_FOUND);

      const randomSetSummary = sets[Math.floor(Math.random() * sets.length)];
      const setDetails = await this.tcgdex.fetch('sets', randomSetSummary.id);

      if (!setDetails || !setDetails.cards || setDetails.cards.length === 0) {
        return this.startGame(); // Retry
      }

      const randomCardResume =
        setDetails.cards[Math.floor(Math.random() * setDetails.cards.length)];
      const card = await this.tcgdex.fetch('cards', randomCardResume.id);

      if (!card || !card.image) {
        return this.startGame(); // Retry
      }

      const fullImageUrl = `${card.image}/high.png`;

      // 2. Download and Crop Image
      const imageBuffer = await this.downloadImage(fullImageUrl);
      const croppedImageBase64 = await this.cropImage(imageBuffer);

      // 3. Create Game Session
      const gameId = uuidv4();
      this.activeGames.set(gameId, {
        cardId: card.id,
        name: card.name,
        fullImageUrl: fullImageUrl,
        set: card.set.name,
      });

      // 4. Return secure data
      return {
        gameId,
        croppedImage: `data:image/png;base64,${croppedImageBase64}`,
      };
    } catch (error) {
      console.error('Error starting game:', error);
      throw new HttpException(
        'Failed to start game',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  async makeGuess(gameId: string, guess: string) {
    const session = this.activeGames.get(gameId);
    if (!session) {
      throw new HttpException('Game session not found', HttpStatus.NOT_FOUND);
    }

    const normalizedGuess = guess.trim().toLowerCase();
    const normalizedActual = session.name.toLowerCase();

    // Simple check: is the guess contained in the name?
    // e.g. "Pikachu" in "Surfing Pikachu" -> True
    const isCorrect =
      normalizedActual.includes(normalizedGuess) && normalizedGuess.length >= 3;

    if (isCorrect) {
      this.activeGames.delete(gameId); // Clean up
      return {
        correct: true,
        name: session.name,
        fullImageUrl: session.fullImageUrl,
        set: session.set,
      };
    } else {
      return {
        correct: false,
      };
    }
  }

  async giveUp(gameId: string) {
    const session = this.activeGames.get(gameId);
    if (!session) {
      throw new HttpException('Game session not found', HttpStatus.NOT_FOUND);
    }

    this.activeGames.delete(gameId);
    return {
      name: session.name,
      fullImageUrl: session.fullImageUrl,
      set: session.set,
    };
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
