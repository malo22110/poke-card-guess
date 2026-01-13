import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class GameService {
  private readonly apiKey = '0236ceb1-a442-4657-b0ae-f8eeac60e5cc';
  private readonly baseUrl = 'https://api.pokemontcg.io/v2';

  async getRandomCard() {
    try {
      // 1. Fetch all sets
      const setsResponse = await axios.get(`${this.baseUrl}/sets`, {
        headers: { 'X-Api-Key': this.apiKey },
      });

      const sets = setsResponse.data.data;
      if (!sets || sets.length === 0) {
        throw new HttpException('No sets found', HttpStatus.NOT_FOUND);
      }

      // 2. Pick a random set
      const randomSet = sets[Math.floor(Math.random() * sets.length)];

      // 3. Fetch cards for that specific set
      const cardsResponse = await axios.get(`${this.baseUrl}/cards`, {
        headers: { 'X-Api-Key': this.apiKey },
        params: { q: `set.id:${randomSet.id}` },
      });

      const cards = cardsResponse.data.data;

      // Filter for cards with images
      const validCards = cards.filter((c: any) => c.images && c.images.large);

      if (!validCards || validCards.length === 0) {
        // Retry if no valid cards found in this set (simple recursion)
        return this.getRandomCard();
      }

      // 4. Pick a random card
      const randomCard =
        validCards[Math.floor(Math.random() * validCards.length)];

      return {
        id: randomCard.id,
        name: randomCard.name,
        images: randomCard.images,
        set: randomCard.set,
        types: randomCard.types,
        supertype: randomCard.supertype,
      };
    } catch (error) {
      console.error('Error fetching card:', error);
      throw new HttpException(
        'Failed to fetch random card',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
