import {
  Controller,
  Post,
  Body,
  UseGuards,
  Req,
  Get,
  Param,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request } from 'express';
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
  createLobby(
    @Body()
    body: {
      rounds?: number;
      sets?: string[];
      secretOnly?: boolean;
      rarities?: string[];
    },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : 'guest-host-' + Math.random().toString(36).substr(2, 9);

    return this.gameService.createLobby(userId, {
      rounds: body.rounds,
      sets: body.sets,
      secretOnly: body.secretOnly,
      rarities: body.rarities,
    });
  }

  @Post('join')
  @UseGuards(OptionalJwtAuthGuard)
  joinLobby(
    @Body() body: { lobbyId: string; guestId?: string },
    @Req() req: any,
  ) {
    const userId = req.user
      ? req.user.id || req.user.userId
      : body.guestId || 'guest-' + Math.random().toString(36).substr(2, 9);

    // Call service to join
    const lobby = this.gameService.joinLobby(userId, body.lobbyId);

    // Return lobby info AND the userId (guestId) if it was generated/used, so frontend can store it
    return {
      ...lobby,
      guestId: !req.user ? userId : undefined,
    };
  }

  @Post('start')
  @UseGuards(OptionalJwtAuthGuard)
  async startGame(
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
