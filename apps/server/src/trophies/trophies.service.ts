import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class TrophiesService {
  constructor(private prisma: PrismaService) {}

  async getAllTrophies() {
    return this.prisma.trophy.findMany({
      orderBy: [{ category: 'asc' }, { requirement: 'asc' }],
    });
  }

  async getUserTrophies(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    const unlocked = await this.prisma.userTrophy.findMany({
      where: { userId },
      include: { trophy: true },
      orderBy: { unlockedAt: 'desc' },
    });

    const allTrophies = await this.getAllTrophies();
    const unlockedIds = new Set(unlocked.map((ut) => ut.trophyId));

    const userRank = user ? await this.getUserRank(user.totalScore) : 0;

    const locked = allTrophies
      .filter((t) => !unlockedIds.has(t.id))
      .map((t) => ({
        ...t,
        progress: user ? this.calculateProgress(user, t, userRank) : 0,
      }));

    return {
      unlocked,
      locked,
      totalUnlocked: unlocked.length,
      totalTrophies: allTrophies.length,
    };
  }

  private calculateProgress(
    user: any,
    trophy: any,
    userRank: number = 0,
  ): number {
    const { category, key } = trophy;

    // Handle Speed
    if (category === 'speed') {
      if (key === 'speedrunner') return 999.0;
      return user.fastestGuess || 999.0;
    }
    // Handle Speed Demon (special)
    if (key === 'speed_demon' || key === 'lightning_fast') {
      return user.fastestGuess || 999.0;
    }

    switch (category) {
      case 'leaderboard':
        return user.totalScore > 0 ? userRank : 0;
      case 'score':
        return user.totalScore;
      case 'games':
        return user.gamesPlayed;
      case 'wins':
        return user.gamesWon;
      case 'streak':
        return user.bestStreak;
      case 'cards':
        return user.cardsGuessed;
      case 'social':
        return user.sharesCount;
      case 'donation':
        return Math.floor((user.totalDonated || 0) / 100);
      case 'set':
        try {
          const sets = JSON.parse(user.uniqueSetsGuessed || '[]');
          return Array.isArray(sets) ? sets.length : 0;
        } catch {
          return 0;
        }
      case 'rarity':
        try {
          const stats = JSON.parse(user.rarityStats || '{}');
          let targetRarity = '';
          if (key === 'rare_hunter') targetRarity = 'Rare';
          else if (key === 'ultra_rare_collector') targetRarity = 'Ultra Rare';
          else if (key === 'secret_seeker') targetRarity = 'Secret Rare';
          if (targetRarity) return stats[targetRarity] || 0;
          return stats[key] || 0;
        } catch {
          return 0;
        }
      case 'special':
        return this.calculateSpecialProgress(user, key);
      default:
        return 0;
    }
  }

  private calculateSpecialProgress(user: any, key: string): number {
    switch (key) {
      case 'perfect_round':
        return user.bestRoundScore || 0;
      case 'personal_best': // Assuming there is a personal best trophy key
        return user.timesBeatenHighScore || 0;
      default:
        return 0;
    }
  }

  async checkAndAwardTrophies(
    userId: string,
    options?: { category?: string; excludeCategories?: string[] },
  ) {
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
    const newlyUnlocked: any[] = [];

    for (const trophy of allTrophies) {
      if (unlockedTrophyIds.has(trophy.id)) {
        continue; // Already unlocked
      }

      if (options?.category && trophy.category !== options.category) {
        continue;
      }

      if (
        options?.excludeCategories &&
        options.excludeCategories.includes(trophy.category)
      ) {
        continue;
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

  async unlockTrophy(userId: string, trophyKey: string) {
    const trophy = await this.prisma.trophy.findUnique({
      where: { key: trophyKey },
    });
    if (!trophy) return null;

    const existing = await this.prisma.userTrophy.findUnique({
      where: {
        userId_trophyId: {
          userId,
          trophyId: trophy.id,
        },
      },
    });

    if (existing) return null;

    return await this.prisma.userTrophy.create({
      data: {
        userId,
        trophyId: trophy.id,
      },
      include: { trophy: true },
    });
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
        return await this.checkLeaderboardTrophy(user, key, requirement);

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
        return user.bestRoundScore >= requirement;

      case 'speed_demon':
      case 'lightning_fast':
        return (user.fastestGuess || 999.0) <= requirement;

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
    requirement: number,
  ): Promise<boolean> {
    if (key === 'multi_mode_master') {
      // TODO: Implement mode-specific leaderboard tracking
      return false;
    }
    if (user.totalScore === 0) return false;
    const rank = await this.getUserRank(user.totalScore);
    return rank <= requirement;
  }

  private async getUserRank(score: number): Promise<number> {
    const betterPlayers = await this.prisma.user.count({
      where: {
        totalScore: {
          gt: score,
        },
      },
    });
    return betterPlayers + 1;
  }

  private async checkPersonalBestTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // Check based on how many times user has beaten their high score
    return user.timesBeatenHighScore >= requirement;
  }

  private async checkRarityTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // Check based on rarity stats
    if (!user.rarityStats) return false;

    try {
      const stats = JSON.parse(user.rarityStats);
      let targetRarity = '';
      if (key === 'rare_hunter') targetRarity = 'Rare';
      else if (key === 'ultra_rare_collector') targetRarity = 'Ultra Rare';
      else if (key === 'secret_seeker') targetRarity = 'Secret Rare';

      const userCount = targetRarity
        ? stats[targetRarity] || 0
        : stats[key] || 0;
      return userCount >= requirement;
    } catch {
      return false;
    }
  }

  private async checkSetTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // Check based on unique sets guessed
    if (!user.uniqueSetsGuessed) return false;

    try {
      const uniqueSets = JSON.parse(user.uniqueSetsGuessed);
      return Array.isArray(uniqueSets) && uniqueSets.length >= requirement;
    } catch {
      return false;
    }
  }

  private async checkSpeedTrophy(
    user: any,
    key: string,
    requirement: number,
  ): Promise<boolean> {
    // All speed trophies now check fastest single guess time
    // Requirement is in seconds, lower is better
    return (user.fastestGuess || 999.0) <= requirement;
  }

  private async getAverageGuessTime(userId: string): Promise<number> {
    const sessions = await this.prisma.gameSession.findMany({
      where: { userId },
      orderBy: { playedAt: 'desc' },
      take: 20,
      select: { roundStats: true },
    });

    let totalTime = 0;
    let totalGuesses = 0;

    for (const session of sessions) {
      if (!session.roundStats) continue;
      try {
        const stats = JSON.parse(session.roundStats as string);
        if (Array.isArray(stats)) {
          for (const round of stats) {
            if (Array.isArray(round.stats)) {
              const userStat = round.stats.find(
                (s: any) => s.userId === userId,
              );
              if (userStat && userStat.timeTaken) {
                totalTime += userStat.timeTaken;
                totalGuesses++;
              }
            }
          }
        }
      } catch {}
    }

    if (totalGuesses === 0) return 999.0;
    return totalTime / totalGuesses / 1000; // Average in seconds
  }

  private async getBestGameTime(userId: string): Promise<number> {
    const sessions = await this.prisma.gameSession.findMany({
      where: { userId },
      select: { rounds: true, roundStats: true },
    });

    let bestTime = 99999;

    for (const session of sessions) {
      if (session.rounds < 10) continue;
      try {
        const stats = JSON.parse(session.roundStats as string);
        if (Array.isArray(stats)) {
          const totalTimeMs = stats.reduce((sum: number, item: any) => {
            // item.stats is Array of { userId, timeTaken, ... }
            // We need to filter for the current user (although GameSession is per user, the history might contain all lobby players?
            // Actually saveGameSession saves the FULL lobby history to the user's session entry?
            // Yes, code: roundStats: JSON.stringify(Array.from(lobby.history...))
            // So we must find our userId.
            if (Array.isArray(item.stats)) {
              const userStat = item.stats.find((s: any) => s.userId === userId);
              return sum + (userStat?.timeTaken || 0);
            }
            return sum;
          }, 0);

          const totalSeconds = totalTimeMs / 1000;
          if (totalSeconds > 0 && totalSeconds < bestTime) {
            bestTime = totalSeconds;
          }
        }
      } catch (e) {
        continue;
      }
    }
    return bestTime;
  }
}
