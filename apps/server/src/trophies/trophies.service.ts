import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class TrophiesService implements OnModuleInit {
  private readonly logger = new Logger(TrophiesService.name);

  constructor(private prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedTrophies();
  }

  async seedTrophies() {
    const trophies = [
      // Score-Based Trophies (5)
      {
        key: 'first_steps',
        name: 'First Steps',
        description: 'Score 50,000 total points',
        category: 'score',
        tier: 'bronze',
        icon: '🥉',
        requirement: 50000,
      },
      {
        key: 'rising_star',
        name: 'Rising Star',
        description: 'Score 250,000 total points',
        category: 'score',
        tier: 'silver',
        icon: '🥈',
        requirement: 250000,
      },
      {
        key: 'card_master',
        name: 'Card Master',
        description: 'Score 1,000,000 total points',
        category: 'score',
        tier: 'gold',
        icon: '🥇',
        requirement: 1000000,
      },
      {
        key: 'legend',
        name: 'Legend',
        description: 'Score 5,000,000 total points',
        category: 'score',
        tier: 'diamond',
        icon: '💎',
        requirement: 5000000,
      },
      {
        key: 'hall_of_fame',
        name: 'Hall of Fame',
        description: 'Score 10,000,000 total points',
        category: 'score',
        tier: 'diamond',
        icon: '👑',
        requirement: 10000000,
      },
      // Game-Based Trophies (5)
      {
        key: 'beginner',
        name: 'Beginner',
        description: 'Play 10 games',
        category: 'games',
        tier: 'bronze',
        icon: '🎮',
        requirement: 10,
      },
      {
        key: 'regular',
        name: 'Regular',
        description: 'Play 50 games',
        category: 'games',
        tier: 'silver',
        icon: '🎮',
        requirement: 50,
      },
      {
        key: 'veteran',
        name: 'Veteran',
        description: 'Play 100 games',
        category: 'games',
        tier: 'gold',
        icon: '🎮',
        requirement: 100,
      },
      {
        key: 'dedicated',
        name: 'Dedicated',
        description: 'Play 500 games',
        category: 'games',
        tier: 'diamond',
        icon: '🎮',
        requirement: 500,
      },
      {
        key: 'addicted',
        name: 'Addicted',
        description: 'Play 1,000 games',
        category: 'games',
        tier: 'diamond',
        icon: '🎮',
        requirement: 1000,
      },
      // Win-Based Trophies (5)
      {
        key: 'first_victory',
        name: 'First Victory',
        description: 'Win your first game',
        category: 'wins',
        tier: 'bronze',
        icon: '🏆',
        requirement: 1,
      },
      {
        key: 'winner',
        name: 'Winner',
        description: 'Win 10 games',
        category: 'wins',
        tier: 'silver',
        icon: '🏆',
        requirement: 10,
      },
      {
        key: 'champion',
        name: 'Champion',
        description: 'Win 50 games',
        category: 'wins',
        tier: 'gold',
        icon: '🏆',
        requirement: 50,
      },
      {
        key: 'unbeatable',
        name: 'Unbeatable',
        description: 'Win 100 games',
        category: 'wins',
        tier: 'diamond',
        icon: '🏆',
        requirement: 100,
      },
      {
        key: 'dominator',
        name: 'Dominator',
        description: 'Win 250 games',
        category: 'wins',
        tier: 'diamond',
        icon: '🏆',
        requirement: 250,
      },
      // Streak Trophies (4)
      {
        key: 'hot_streak',
        name: 'Hot Streak',
        description: 'Guess 3 cards correctly in a row',
        category: 'streak',
        tier: 'silver',
        icon: '🔥',
        requirement: 3,
      },
      {
        key: 'on_fire',
        name: 'On Fire',
        description: 'Guess 5 cards correctly in a row',
        category: 'streak',
        tier: 'gold',
        icon: '🔥',
        requirement: 5,
      },
      {
        key: 'unstoppable',
        name: 'Unstoppable',
        description: 'Guess 10 cards correctly in a row',
        category: 'streak',
        tier: 'diamond',
        icon: '🔥',
        requirement: 10,
      },
      {
        key: 'legendary_streak',
        name: 'Legendary Streak',
        description: 'Guess 15 cards correctly in a row',
        category: 'streak',
        tier: 'diamond',
        icon: '🔥',
        requirement: 15,
      },
      // Card-Based Trophies (5)
      {
        key: 'quick_guesser',
        name: 'Quick Guesser',
        description: 'Guess 100 cards correctly',
        category: 'cards',
        tier: 'bronze',
        icon: '🎴',
        requirement: 100,
      },
      {
        key: 'card_expert',
        name: 'Card Expert',
        description: 'Guess 500 cards correctly',
        category: 'cards',
        tier: 'silver',
        icon: '🎴',
        requirement: 500,
      },
      {
        key: 'card_genius',
        name: 'Card Genius',
        description: 'Guess 1,000 cards correctly',
        category: 'cards',
        tier: 'gold',
        icon: '🎴',
        requirement: 1000,
      },
      {
        key: 'pokedex_complete',
        name: 'Pokédex Complete',
        description: 'Guess 5,000 cards correctly',
        category: 'cards',
        tier: 'diamond',
        icon: '🎴',
        requirement: 5000,
      },
      {
        key: 'master_collector',
        name: 'Master Collector',
        description: 'Guess 10,000 cards correctly',
        category: 'cards',
        tier: 'diamond',
        icon: '🎴',
        requirement: 10000,
      },
      // Special Trophies (10)
      {
        key: 'perfect_round',
        name: 'Perfect Round',
        description: 'Score 25,000+ points in a single round',
        category: 'special',
        tier: 'special',
        icon: '⭐',
        requirement: 25000,
      },
      {
        key: 'perfectionist',
        name: 'Perfectionist',
        description: 'Complete a game with 100% accuracy',
        category: 'special',
        tier: 'special',
        icon: '✨',
        requirement: 100,
      },
      {
        key: 'flawless_victory',
        name: 'Flawless Victory',
        description: 'Win a 10+ round game with 100% accuracy',
        category: 'special',
        tier: 'special',
        icon: '✨',
        requirement: 10,
      },
      {
        key: 'night_owl',
        name: 'Night Owl',
        description: 'Play a game between midnight and 4 AM',
        category: 'special',
        tier: 'fun',
        icon: '🦉',
        requirement: 1,
      },
      {
        key: 'early_bird',
        name: 'Early Bird',
        description: 'Play a game between 5 AM and 7 AM',
        category: 'special',
        tier: 'fun',
        icon: '🐦',
        requirement: 1,
      },
      {
        key: 'weekend_warrior',
        name: 'Weekend Warrior',
        description: 'Play 20 games on a weekend',
        category: 'special',
        tier: 'fun',
        icon: '🎉',
        requirement: 20,
      },
      {
        key: 'first_share',
        name: 'First Share',
        description: 'Share your score for the first time',
        category: 'social',
        tier: 'bronze',
        icon: '📤',
        requirement: 1,
      },
      {
        key: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Share your score 10 times',
        category: 'social',
        tier: 'silver',
        icon: '🦋',
        requirement: 10,
      },
      {
        key: 'influencer',
        name: 'Influencer',
        description: 'Share your score 50 times',
        category: 'social',
        tier: 'gold',
        icon: '📱',
        requirement: 50,
      },
      // Leaderboard Trophies (5)
      {
        key: 'challenger',
        name: 'Challenger',
        description: 'Beat an existing #1 player to take their spot',
        category: 'leaderboard',
        tier: 'diamond',
        icon: '⚔️',
        requirement: 1,
      },
      {
        key: 'top_player',
        name: 'Top Player',
        description: 'Reach #1 on any game mode leaderboard',
        category: 'leaderboard',
        tier: 'gold',
        icon: '🥇',
        requirement: 1,
      },
      {
        key: 'podium_finish',
        name: 'Podium Finish',
        description: 'Reach top 3 on any game mode leaderboard',
        category: 'leaderboard',
        tier: 'silver',
        icon: '🥈',
        requirement: 3,
      },
      {
        key: 'top_10',
        name: 'Top 10',
        description: 'Reach top 10 on any game mode leaderboard',
        category: 'leaderboard',
        tier: 'bronze',
        icon: '🥉',
        requirement: 10,
      },
      {
        key: 'multi_mode_master',
        name: 'Multi-Mode Master',
        description: 'Reach top 10 in 3 different game modes',
        category: 'leaderboard',
        tier: 'gold',
        icon: '🎯',
        requirement: 3,
      },
      // Personal Best Trophies (4)
      {
        key: 'self_improvement',
        name: 'Self Improvement',
        description: 'Beat your own high score on any game mode',
        category: 'personal_best',
        tier: 'bronze',
        icon: '📈',
        requirement: 1,
      },
      {
        key: 'consistency',
        name: 'Consistency',
        description: 'Beat your own high score 5 times',
        category: 'personal_best',
        tier: 'silver',
        icon: '📈',
        requirement: 5,
      },
      {
        key: 'always_improving',
        name: 'Always Improving',
        description: 'Beat your own high score 10 times',
        category: 'personal_best',
        tier: 'gold',
        icon: '📈',
        requirement: 10,
      },
      {
        key: 'unstoppable_growth',
        name: 'Unstoppable Growth',
        description: 'Beat your own high score 25 times',
        category: 'personal_best',
        tier: 'diamond',
        icon: '📈',
        requirement: 25,
      },
      // Rarity Trophies (9)
      {
        key: 'common_collector',
        name: 'Common Collector',
        description: 'Correctly guess 5 common cards',
        category: 'rarity',
        tier: 'bronze',
        icon: '⚪',
        requirement: 5,
      },
      {
        key: 'uncommon_collector',
        name: 'Uncommon Collector',
        description: 'Correctly guess 10 uncommon cards',
        category: 'rarity',
        tier: 'bronze',
        icon: '🟢',
        requirement: 10,
      },
      {
        key: 'rare_hunter',
        name: 'Rare Hunter',
        description: 'Correctly guess 20 rare cards',
        category: 'rarity',
        tier: 'silver',
        icon: '💎',
        requirement: 20,
      },
      {
        key: 'double_rare_hunter',
        name: 'Double Rare Hunter',
        description: 'Correctly guess 30 double rare cards',
        category: 'rarity',
        tier: 'silver',
        icon: '✨',
        requirement: 30,
      },
      {
        key: 'ultra_rare_collector',
        name: 'Ultra Rare Collector',
        description: 'Correctly guess 50 ultra rare cards',
        category: 'rarity',
        tier: 'gold',
        icon: '🌟',
        requirement: 50,
      },
      {
        key: 'illustration_admirer',
        name: 'Illustration Admirer',
        description: 'Correctly guess 60 illustration rare cards',
        category: 'rarity',
        tier: 'gold',
        icon: '🖼️',
        requirement: 60,
      },
      {
        key: 'secret_seeker',
        name: 'Secret Seeker',
        description: 'Correctly guess 75 secret rare cards',
        category: 'rarity',
        tier: 'diamond',
        icon: '💎',
        requirement: 75,
      },
      {
        key: 'special_investigator',
        name: 'Special Investigator',
        description: 'Correctly guess 80 special illustration rare cards',
        category: 'rarity',
        tier: 'diamond',
        icon: '🔍',
        requirement: 80,
      },
      {
        key: 'hyper_hunter',
        name: 'Hyper Hunter',
        description: 'Correctly guess 100 hyper rare cards',
        category: 'rarity',
        tier: 'diamond',
        icon: '🌈',
        requirement: 100,
      },
      {
        key: 'rarity_master',
        name: 'Rarity Master',
        description: 'Guess at least 1 card from 8 different rarities',
        category: 'rarity',
        tier: 'special',
        icon: '👑',
        requirement: 8,
      },
      // Set Trophies (4)
      {
        key: 'set_explorer',
        name: 'Set Explorer',
        description: 'Guess cards from 10 different sets',
        category: 'set',
        tier: 'bronze',
        icon: '🎨',
        requirement: 10,
      },
      {
        key: 'set_connoisseur',
        name: 'Set Connoisseur',
        description: 'Guess cards from 25 different sets',
        category: 'set',
        tier: 'silver',
        icon: '🎨',
        requirement: 25,
      },
      {
        key: 'set_master',
        name: 'Set Master',
        description: 'Guess cards from 50 different sets',
        category: 'set',
        tier: 'gold',
        icon: '🎨',
        requirement: 50,
      },
      {
        key: 'complete_collection',
        name: 'Complete Collection',
        description: 'Guess cards from 100 different sets',
        category: 'set',
        tier: 'diamond',
        icon: '🎨',
        requirement: 100,
      },
      // Speed Trophies (4)
      {
        key: 'fast_learner',
        name: 'Quick Thinker',
        description: 'Correctly guess a card in under 5 seconds',
        category: 'speed',
        tier: 'silver',
        icon: '⚡',
        requirement: 5,
      },
      {
        key: 'speed_demon',
        name: 'Speed Demon',
        description: 'Correctly guess a card in under 3 seconds',
        category: 'speed',
        tier: 'gold',
        icon: '⚡',
        requirement: 3,
      },
      {
        key: 'speedrunner',
        name: 'Speedrunner',
        description: 'Correctly guess a card in under 2 seconds',
        category: 'speed',
        tier: 'gold',
        icon: '⚡',
        requirement: 2,
      },
      {
        key: 'reflex_master',
        name: 'Reflex Master',
        description: 'Correctly guess a card in under 1.5 seconds',
        category: 'speed',
        tier: 'diamond',
        icon: '⚡',
        requirement: 1.5,
      },
      // Donation Trophies (4)
      {
        key: 'supporter',
        name: 'Supporter',
        description: 'Make your first donation',
        category: 'donation',
        tier: 'bronze',
        icon: '💝',
        requirement: 1,
      },
      {
        key: 'generous',
        name: 'Generous',
        description: 'Donate $5 or more',
        category: 'donation',
        tier: 'silver',
        icon: '💝',
        requirement: 5,
      },
      {
        key: 'patron',
        name: 'Patron',
        description: 'Donate $20 or more',
        category: 'donation',
        tier: 'gold',
        icon: '💝',
        requirement: 20,
      },
      {
        key: 'benefactor',
        name: 'Benefactor',
        description: 'Donate $50 or more',
        category: 'donation',
        tier: 'diamond',
        icon: '💝',
        requirement: 50,
      },
      {
        key: 'quick_draw',
        name: 'Quick Draw',
        description: 'Be the first to guess a card',
        category: 'event',
        tier: 'gold',
        icon: '⚡',
        requirement: 1,
      },
      {
        key: 'good_sport',
        name: 'Good Sport',
        description: 'Give up a round',
        category: 'event',
        tier: 'bronze',
        icon: '🏳️',
        requirement: 1,
      },
      {
        key: 'slow_poke',
        name: 'Slow Poke',
        description: 'Take more than 25 seconds to guess',
        category: 'event',
        tier: 'bronze',
        icon: '🐢',
        requirement: 25,
      },
      {
        key: 'buzzer_beater',
        name: 'Buzzer Beater',
        description: 'Guess at the last second of the round',
        category: 'event',
        tier: 'silver',
        icon: '⏰',
        requirement: 1,
      },
      // Creator Trophies
      {
        key: 'game_creator',
        name: 'Game Creator',
        description: 'Create your first custom game mode',
        category: 'creator',
        tier: 'bronze',
        icon: '🛠️',
        requirement: 1,
      },
      {
        key: 'community_favorite',
        name: 'Community Favorite',
        description: 'Get 10 upvotes on one of your game modes',
        category: 'creator',
        tier: 'silver',
        icon: '❤️',
        requirement: 10,
      },
      {
        key: 'cleanup_crew',
        name: 'Cleanup Crew',
        description: 'Delete one of your custom game modes',
        category: 'creator',
        tier: 'bronze',
        icon: '🧹',
        requirement: 1,
      },
    ];

    this.logger.log(`Seeding ${trophies.length} trophies...`);
    for (const trophy of trophies) {
      await this.prisma.trophy.upsert({
        where: { key: trophy.key },
        update: trophy,
        create: trophy,
      });
    }
    this.logger.log('Trophies seeded successfully');
  }

  async getAllTrophies() {
    return this.prisma.trophy.findMany({
      orderBy: [{ category: 'asc' }, { requirement: 'asc' }],
    });
  }

  async getUserTrophies(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: { createdGameModes: true },
        },
      },
    });

    const unlocked = await this.prisma.userTrophy.findMany({
      where: { userId },
      include: { trophy: true },
      orderBy: { unlockedAt: 'desc' },
    });

    const allTrophies = await this.getAllTrophies();
    const unlockedIds = new Set(unlocked.map((ut) => ut.trophyId));

    const userRank = user ? await this.getUserRank(user.totalScore) : 0;

    const locked = await Promise.all(
      allTrophies
        .filter((t) => !unlockedIds.has(t.id))
        .map(async (t) => ({
          ...t,
          progress: user ? await this.calculateProgress(user, t, userRank) : 0,
        })),
    );

    return {
      unlocked,
      locked,
      totalUnlocked: unlocked.length,
      totalTrophies: allTrophies.length,
    };
  }

  private async calculateProgress(
    user: any,
    trophy: any,
    userRank: number = 0,
  ): Promise<number> {
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
        if (key === 'multi_mode_master') {
          return await this.getMultiModeMasterProgress(user.id);
        }
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
      case 'creator':
        if (key === 'cleanup_crew') {
          return (user as any).deletedModesCount || 0;
        }
        if (key === 'community_favorite') {
          return await this.getMaxUpvotes(user.id);
        }
        return user._count?.createdGameModes || 0;
      case 'rarity':
        try {
          const stats = JSON.parse(user.rarityStats || '{}');

          if (key === 'rarity_master') {
            return Object.keys(stats).filter((k) => stats[k] > 0).length;
          }

          let targetRarity = '';
          if (key === 'rare_hunter') targetRarity = 'Rare';
          else if (key === 'ultra_rare_collector') targetRarity = 'Ultra Rare';
          else if (key === 'secret_seeker') targetRarity = 'Secret Rare';
          else if (key === 'common_collector') targetRarity = 'Common';
          else if (key === 'uncommon_collector') targetRarity = 'Uncommon';
          else if (key === 'double_rare_hunter') targetRarity = 'Double Rare';
          else if (key === 'illustration_admirer')
            targetRarity = 'Illustration Rare';
          else if (key === 'special_investigator')
            targetRarity = 'Special Illustration Rare';
          else if (key === 'hyper_hunter') targetRarity = 'Hyper Rare';

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

  private async getMultiModeMasterProgress(userId: string): Promise<number> {
    const userModes = await this.prisma.gameSession.findMany({
      where: { userId, gameModeId: { not: null } },
      distinct: ['gameModeId'],
      select: { gameModeId: true },
    });

    let eligibleModes = 0;
    for (const mode of userModes) {
      if (!mode.gameModeId) continue;

      // Get user's best score in this mode
      const bestSession = await this.prisma.gameSession.aggregate({
        where: { userId, gameModeId: mode.gameModeId },
        _max: { score: true },
      });
      const myScore = bestSession._max.score || 0;
      if (myScore === 0) continue;

      // Count users with better score
      const betterPlayers = await this.prisma.gameSession.groupBy({
        by: ['userId'],
        where: {
          gameModeId: mode.gameModeId,
        },
        having: {
          score: {
            _max: { gt: myScore },
          },
        },
      });

      const rank = betterPlayers.length + 1;
      if (rank <= 10) eligibleModes++;
    }
    return eligibleModes;
  }

  private async getMaxUpvotes(userId: string): Promise<number> {
    const modes = await this.prisma.gameMode.findMany({
      where: { creatorId: userId },
      include: { _count: { select: { upvotes: true } } },
    });

    return modes.reduce((max, m) => Math.max(max, m._count.upvotes || 0), 0);
  }

  async checkUpvoteTrophies(userId: string) {
    const modes = await this.prisma.gameMode.findMany({
      where: { creatorId: userId },
      include: { _count: { select: { upvotes: true } } },
    });

    const maxUpvotes = modes.reduce(
      (max, m) => Math.max(max, m._count.upvotes || 0),
      0,
    );

    if (maxUpvotes >= 10) {
      return this.unlockTrophy(userId, 'community_favorite');
    }
    return null;
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
        _count: {
          select: { createdGameModes: true },
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

      case 'creator':
        // Special handling for community_favorite - check upvotes instead of creation count
        if (key === 'community_favorite') {
          const modes = await this.prisma.gameMode.findMany({
            where: { creatorId: user.id },
            include: { _count: { select: { upvotes: true } } },
          });
          const maxUpvotes = modes.reduce(
            (max, m) => Math.max(max, m._count.upvotes || 0),
            0,
          );
          return maxUpvotes >= requirement;
        }

        if (key === 'cleanup_crew') {
          return (user.deletedModesCount || 0) >= requirement;
        }

        // For other creator trophies, check creation count
        return (user._count?.createdGameModes || 0) >= requirement;

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
      const qualifyingModes = await this.getMultiModeMasterProgress(user.id);
      return qualifyingModes >= requirement;
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

      if (key === 'rarity_master') {
        const uniqueRarities = Object.keys(stats).filter(
          (k) => stats[k] > 0,
        ).length;
        return uniqueRarities >= requirement;
      }

      let targetRarity = '';
      if (key === 'rare_hunter') targetRarity = 'Rare';
      else if (key === 'ultra_rare_collector') targetRarity = 'Ultra Rare';
      else if (key === 'secret_seeker') targetRarity = 'Secret Rare';
      else if (key === 'common_collector') targetRarity = 'Common';
      else if (key === 'uncommon_collector') targetRarity = 'Uncommon';
      else if (key === 'double_rare_hunter') targetRarity = 'Double Rare';
      else if (key === 'illustration_admirer')
        targetRarity = 'Illustration Rare';
      else if (key === 'special_investigator')
        targetRarity = 'Special Illustration Rare';
      else if (key === 'hyper_hunter') targetRarity = 'Hyper Rare';

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
