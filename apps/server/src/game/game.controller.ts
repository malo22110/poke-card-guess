import {
  Controller,
  Post,
  Body,
  UseGuards,
  Req,
  Get,
  Param,
} from '@nestjs/common';
import { GameService } from './game.service';
import { OptionalJwtAuthGuard } from '../auth/optional-jwt-auth.guard';

interface RequestWithUser extends Request {
  user: {
    id: string;
    userId: string;
  };
}

@Controller('game')
export class GameController {
  constructor(private readonly gameService: GameService) {}

  @Post('create')
  @UseGuards(OptionalJwtAuthGuard)
  async createLobby(
    @Body()
    body: {
      rounds?: number;
      sets?: string[];
      secretOnly?: boolean;
      rarities?: string[];
      guestName?: string;
      gameModeId?: string;
    },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : 'guest-host-' + Math.random().toString(36).substr(2, 9);

    return await this.gameService.createLobby(
      userId,
      {
        rounds: body.rounds,
        sets: body.sets,
        secretOnly: body.secretOnly,
        rarities: body.rarities,
      },
      req.user?.name || body.guestName,
      body.gameModeId,
    );
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

    // If authenticated and no name provided, we could fetch it, but for now fallback to userId is okay
    // or we can expect the client to send 'guestName' (which is just 'displayName') even for auth users if we want.
    // However, since we updated the profile, maybe we should fetch it.
    // But I haven't injected UsersService here yet.

    // Call service to join
    // Fix argument order: lobbyId, userId, userName
    const lobby = await this.gameService.joinLobby(
      body.lobbyId,
      userId,
      userName || 'Guest',
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
}
