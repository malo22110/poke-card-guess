import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TrophiesService {
  constructor(private prisma: PrismaService) {}

  async getAllTrophies() {
    return this.prisma.trophy.findMany({
      orderBy: [{ category: 'asc' }, { requirement: 'asc' }],
    });
  }

  async getUserTrophies(userId: string) {
    const unlocked = await this.prisma.userTrophy.findMany({
      where: { userId },
      include: { trophy: true },
      orderBy: { unlockedAt: 'desc' },
    });

    const allTrophies = await this.getAllTrophies();
    const unlockedIds = new Set(unlocked.map((ut) => ut.trophyId));

    const locked = allTrophies.filter((t) => !unlockedIds.has(t.id));

    return {
      unlocked,
      locked,
      totalUnlocked: unlocked.length,
      totalTrophies: allTrophies.length,
    };
  }

  async checkAndAwardTrophies(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        trophies: {
          include: { trophy: true },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    const allTrophies = await this.getAllTrophies();
    const unlockedTrophyIds = new Set(user.trophies.map((ut) => ut.trophyId));
    const newlyUnlocked = [];

    for (const trophy of allTrophies) {
      if (unlockedTrophyIds.has(trophy.id)) {
        continue; // Already unlocked
      }

      const shouldUnlock = await this.checkTrophyRequirement(user, trophy);

      if (shouldUnlock) {
        const userTrophy = await this.prisma.userTrophy.create({
          data: {
            userId: user.id,
            trophyId: trophy.id,
          },
          include: { trophy: true },
        });
        newlyUnlocked.push(userTrophy);
      }
    }

    return newlyUnlocked;
  }

  private async checkTrophyRequirement(
    user: any,
    trophy: any,
  ): Promise<boolean> {
    const { category, key, requirement } = trophy;

    switch (category) {
      case 'score':
        return user.totalScore >= requirement;

      case 'games':
        return user.gamesPlayed >= requirement;

      case 'wins':
        return user.gamesWon >= requirement;

      case 'streak':
        return user.bestStreak >= requirement;

      case 'cards':
        return user.cardsGuessed >= requirement;

      case 'social':
        return user.sharesCount >= requirement;

      case 'donation':
        // requirement is in dollars, totalDonated is in cents
        return user.totalDonated >= requirement * 100;

      case 'special':
        return await this.checkSpecialTrophy(user, key, requirement);

      case 'leaderboard':
        return await this.checkLeaderboardTrophy(user, key);

      case 'personal_best':
        return await this.checkPersonalBestTrophy(user, key, requirement);

      case 'rarity':
        return await this.checkRarityTrophy(user, key, requirement);

      case 'set':
        return await this.checkSetTrophy(user, key, requirement);

      case 'speed':
        return await this.checkSpeedTrophy(user, key, requirement);

      default:
        return false;
    }
  }

  private async checkSpecialTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // These require checking game sessions
    const sessions = await this.prisma.gameSession.findMany({
      where: { userId: user.id },
      orderBy: { playedAt: 'desc' },
    });

    switch (key) {
      case 'perfect_round':
        // Check if any session has a round score >= 25000
        // This would need to be tracked per round, not per session
        // For now, return false - needs round-level tracking
        return false;

      case 'speed_demon':
      case 'lightning_fast':
        // Would need per-round timing data
        return false;

      case 'perfectionist':
        return sessions.some((s) => s.score === s.maxScore && s.maxScore > 0);

      case 'flawless_victory':
        return sessions.some(
          (s) => s.rounds >= 10 && s.score === s.maxScore && s.maxScore > 0,
        );

      case 'night_owl':
      case 'early_bird':
      case 'weekend_warrior':
        return await this.checkTimeBasedTrophy(user, key);

      default:
        return false;
    }
  }

  private async checkTimeBasedTrophy(user: any, key: string): Promise<boolean> {
    const sessions = await this.prisma.gameSession.findMany({
      where: { userId: user.id },
    });

    switch (key) {
      case 'night_owl': {
        return sessions.some((s) => {
          const hour = new Date(s.playedAt).getHours();
          return hour >= 0 && hour < 4;
        });
      }

      case 'early_bird': {
        return sessions.some((s) => {
          const hour = new Date(s.playedAt).getHours();
          return hour >= 5 && hour < 7;
        });
      }

      case 'weekend_warrior': {
        const weekendGames = sessions.filter((s) => {
          const day = new Date(s.playedAt).getDay();
          return day === 0 || day === 6; // Sunday or Saturday
        });
        return weekendGames.length >= 20;
      }

      default:
        return false;
    }
  }

  private async checkLeaderboardTrophy(
    user: any,
    key: string,
  ): Promise<boolean> {
    // TODO: Implement leaderboard checking logic
    // This requires querying leaderboard positions
    return false;
  }

  private async checkPersonalBestTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // TODO: Track personal best improvements
    // This requires storing historical best scores per game mode
    return false;
  }

  private async checkRarityTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // TODO: Track cards guessed by rarity
    // This requires storing card metadata with guesses
    return false;
  }

  private async checkSetTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // TODO: Track unique sets from guessed cards
    // This requires storing set information with guesses
    return false;
  }

  private async checkSpeedTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // TODO: Track game completion times
    // This requires storing game duration data
    return false;
  }
}
