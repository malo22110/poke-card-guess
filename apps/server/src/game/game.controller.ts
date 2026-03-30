import {
  Controller,
  Post,
  Body,
  UseGuards,
  Req,
  Get,
  Param,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { GameService } from './game.service';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';
import { PrismaService } from '../prisma.service';

interface RequestWithUser extends Request {
  user: {
    id: string;
    userId: string;
    name?: string;
  };
}

@Controller('game')
export class GameController {
  constructor(
    private readonly gameService: GameService,
    private readonly prisma: PrismaService,
  ) {}

  /** Fetch the authenticated user's picture from DB (or null for guests). */
  private async getUserPicture(userId: string | null): Promise<string | null> {
    if (!userId) return null;
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { picture: true },
      });
      return user?.picture ?? null;
    } catch {
      return null;
    }
  }

  @Post('create')
  @UseGuards(OptionalJwtAuthGuard)
  async createLobby(
    @Body()
    body: {
      rounds?: number;
      sets?: string[];
      secretOnly?: boolean;
      rarities?: string[];
      difficulty?: 'normal' | 'easy';
      guestName?: string;
      gameModeId?: string;
    },
    @Req() req: any,
  ) {
    if (!req.user) {
      throw new HttpException(
        'Only authenticated users can create games',
        HttpStatus.UNAUTHORIZED,
      );
    }
    const userId = req.user.id || req.user.userId;
    const picture = await this.getUserPicture(userId);

    const lobby = await this.gameService.createLobby(
      userId,
      {
        rounds: body.rounds,
        sets: body.sets,
        secretOnly: body.secretOnly,
        rarities: body.rarities,
        difficulty: body.difficulty,
      },
      req.user.name || body.guestName, // Prioritize auth name
      body.gameModeId,
    );

    // Backfill the host picture which is initialized as null in createLobby
    if (picture) {
      const inMemoryLobby = this.gameService.getLobby(lobby.id);
      if (inMemoryLobby) {
        inMemoryLobby.playerPictures.set(userId, picture);
      }
    }

    return lobby;
  }

  @Post('join')
  @UseGuards(OptionalJwtAuthGuard)
  async joinLobby(
    @Body() body: { lobbyId: string; guestId?: string; guestName?: string },
    @Req() req: any,
  ) {
    let userId = req.user
      ? req.user.id || req.user.userId
      : body.guestId || 'guest-' + Math.random().toString(36).substr(2, 9);

    let userName = body.guestName;

    const picture = await this.getUserPicture(req.user ? userId : null);

    // Call service to join
    const lobby = await this.gameService.joinLobby(
      body.lobbyId,
      userId,
      userName || 'Guest',
      picture,
    );

    // Return lobby info AND the userId (guestId) if it was generated/used
    return {
      ...lobby,
      guestId: !req.user ? userId : undefined,
    };
  }

  @Post('start')
  @UseGuards(OptionalJwtAuthGuard)
  startGame(
    @Body() body: { lobbyId: string; guestId?: string },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : body.guestId || 'guest';
    return this.gameService.startGame(body.lobbyId, userId);
  }

  @Post('guess')
  @UseGuards(OptionalJwtAuthGuard)
  async makeGuess(
    @Body() body: { lobbyId: string; guess: string; guestId?: string },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : body.guestId || 'guest';
    return this.gameService.makeGuess(body.lobbyId, userId, body.guess);
  }

  @Get(':lobbyId/status')
  getLobbyStatus(@Param('lobbyId') lobbyId: string) {
    return this.gameService.getLobbyStatus(lobbyId);
  }

  @Post('give-up')
  @UseGuards(OptionalJwtAuthGuard)
  async giveUp(
    @Body() body: { lobbyId: string; guestId?: string },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : body.guestId || 'guest';
    return this.gameService.giveUp(body.lobbyId, userId);
  }

  @Get(':lobbyId/round')
  async getRound(@Param('lobbyId') lobbyId: string) {
    const lobby = this.gameService.getLobby(lobbyId);
    if (!lobby) {
      throw new HttpException('Lobby not found', HttpStatus.NOT_FOUND);
    }
    return await this.gameService.getCurrentRoundData(lobby);
  }

  @Get('sets')
  @UseGuards(OptionalJwtAuthGuard)
  async getSets() {
    return this.gameService.getAvailableSets();
  }

  @Get('rarities')
  @UseGuards(OptionalJwtAuthGuard)
  async getRarities() {
    return await this.gameService.getAvailableRarities();
  }

  @Post('preview-cards')
  @UseGuards(OptionalJwtAuthGuard)
  async getPreviewCards(
    @Body() body: { sets?: string[]; rarities?: string[] },
  ) {
    return this.gameService.getPreviewCards(
      body.sets || [],
      body.rarities || [],
    );
  }
}
