import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { TrophiesService } from '../trophies/trophies.service';
import { GameMode, GameModeUpvote, Prisma } from '@prisma/client';

@Injectable()
export class GameModesService {
  constructor(
    private prisma: PrismaService,
    private trophiesService: TrophiesService,
  ) {
    this.seedOfficialModes();
  }

  async remove(id: string, userId: string) {
    const mode = await this.prisma.gameMode.findUnique({ where: { id } });
    if (!mode) {
      throw new NotFoundException('Game mode not found');
    }

    if (mode.creatorId !== userId) {
      throw new ForbiddenException('You can only delete your own game modes');
    }

    await this.prisma.gameMode.delete({
      where: { id },
    });

    const trophy = await this.trophiesService.unlockTrophy(
      userId,
      'cleanup_crew',
    );
    return { newTrophies: trophy ? [trophy] : [] };
  }

  async create(data: {
    name: string;
    description?: string;
    config: any;
    creatorId: string;
  }) {
    const mode = await this.prisma.gameMode.create({
      data: {
        name: data.name,
        description: data.description,
        configJson: JSON.stringify(data.config),
        creatorId: data.creatorId,
        isOfficial: false,
      },
    });

    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      data.creatorId,
      {
        category: 'creator',
      },
    );
    return { ...mode, newTrophies };
  }

  async upvote(gameModeId: string, userId: string) {
    const existing = await this.prisma.gameModeUpvote.findUnique({
      where: {
        userId_gameModeId: {
          userId,
          gameModeId,
        },
      },
    });

    if (existing) {
      return this.prisma.gameModeUpvote.delete({
        where: { id: existing.id },
      });
    }

    const upvote = await this.prisma.gameModeUpvote.create({
      data: {
        userId,
        gameModeId,
      },
    });

    const gameMode = await this.prisma.gameMode.findUnique({
      where: { id: gameModeId },
      select: { creatorId: true },
    });

    const newTrophies: any[] = [];
    if (gameMode && gameMode.creatorId) {
      const trophy = await this.trophiesService.checkUpvoteTrophies(
        gameMode.creatorId,
      );
      if (trophy) newTrophies.push(trophy);
    }

    return { ...upvote, newTrophies };
  }

  async findAll() {
    return this.prisma.gameMode.findMany({
      include: {
        creator: {
          select: { name: true },
        },
        _count: {
          select: { upvotes: true },
        },
      },
      orderBy: [{ isOfficial: 'desc' }, { upvotes: { _count: 'desc' } }],
    });
  }

  async findOne(id: string) {
    return this.prisma.gameMode.findUnique({
      where: { id },
      include: {
        _count: { select: { upvotes: true } },
      },
    });
  }

  async getLeaderboard(gameModeId: string) {
    const grouped = await this.prisma.gameSession.groupBy({
      by: ['userId'],
      where: { gameModeId },
      _max: {
        score: true,
      },
      orderBy: {
        _max: {
          score: 'desc',
        },
      },
      take: 50,
    });

    const leaderboard = await Promise.all(
      grouped.map(async (group) => {
        return this.prisma.gameSession.findFirst({
          where: {
            gameModeId,
            userId: group.userId,
            score: group._max.score as number,
          },
          include: {
            user: {
              select: { name: true, picture: true, socials: true },
            },
          },
        });
      }),
    );

    return leaderboard.filter((item) => item !== null);
  }

  async seedOfficialModes() {
    const classicName = 'The Classic';
    const classicConfig = {
      rounds: 10,
      sets: ['sv03.5'],
      secretOnly: true,
      rarities: [
        'Chromatique ultra rare',
        'Deux Chromatiques',
        'Dresseur Full Art',
        'HIGH-TECG rare',
        'Holo Rare V',
        'Holo Rare VMAX',
        'Holo Rare VSTAR',
        'Hyper rare',
        'Illustration rare',
        'Illustration spéciale rare',
        'LÉGENDE',
        'Magnifique',
        'Magnifique rare',
        'Méga Hyper Rare',
        'Radieux Rare',
        'Rare Holo LV.X',
        'Rare Noir Blanc',
        'Rare Prime',
        'Shiny rare',
        'Shiny rare V',
        'Shiny rare VMAX',
        'Ultra Rare',
        'Un Chromatique',
      ],
    };

    const classicModes = await this.prisma.gameMode.findMany({
      where: { name: classicName, isOfficial: true },
      orderBy: { createdAt: 'asc' },
    });

    if (classicModes.length > 0) {
      const [keep, ...remove] = classicModes;
      if (remove.length > 0) {
        await this.prisma.gameMode.deleteMany({
          where: { id: { in: remove.map((m) => m.id) } },
        });
        console.log(
          `Removed ${remove.length} duplicate official modes: The Classic`,
        );
      }

      await this.prisma.gameMode.update({
        where: { id: keep.id },
        data: {
          configJson: JSON.stringify(classicConfig),
          description: 'The original challenge. 151 cards, Secret Rares only.',
        },
      });
      console.log('Updated official mode: The Classic');
    } else {
      await this.prisma.gameMode.create({
        data: {
          name: classicName,
          description: 'The original challenge. 151 cards, Secret Rares only.',
          configJson: JSON.stringify(classicConfig),
          isOfficial: true,
        },
      });
      console.log('Seeded official mode: The Classic');
    }

    const pioneersName = 'The Pioneers';
    const pioneersConfig = {
      rounds: 10,
      sets: ['base1'],
      secretOnly: false,
      rarities: ['Rare'],
    };

    const pioneersModes = await this.prisma.gameMode.findMany({
      where: { name: pioneersName, isOfficial: true },
      orderBy: { createdAt: 'asc' },
    });

    if (pioneersModes.length > 0) {
      const [keep, ...remove] = pioneersModes;
      if (remove.length > 0) {
        await this.prisma.gameMode.deleteMany({
          where: { id: { in: remove.map((m) => m.id) } },
        });
        console.log(
          `Removed ${remove.length} duplicate official modes: The Pioneers`,
        );
      }

      await this.prisma.gameMode.update({
        where: { id: keep.id },
        data: {
          configJson: JSON.stringify(pioneersConfig),
          description: 'Back to the roots. Base Set, Rares only.',
        },
      });
      console.log('Updated official mode: The Pioneers');
    } else {
      await this.prisma.gameMode.create({
        data: {
          name: pioneersName,
          description: 'Back to the roots. Base Set, Rares only.',
          configJson: JSON.stringify(pioneersConfig),
          isOfficial: true,
        },
      });
      console.log('Seeded official mode: The Pioneers');
    }
  }
}
