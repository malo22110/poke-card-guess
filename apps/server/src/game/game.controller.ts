import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request } from 'express';
import { GameService } from './game.service';

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
  @UseGuards(AuthGuard('jwt'))
  createLobby(@Body() body: { rounds?: number }, @Req() req: RequestWithUser) {
    // Passport user object can differ, ensuring safety
    const userId = req.user.id || req.user.userId;
    return this.gameService.createLobby(userId, { rounds: body.rounds });
  }

  @Post('join')
  @UseGuards(AuthGuard('jwt'))
  joinLobby(@Body() body: { lobbyId: string }, @Req() req: RequestWithUser) {
    const userId = req.user.id || req.user.userId;
    return this.gameService.joinLobby(userId, body.lobbyId);
  }

  @Post('start')
  @UseGuards(AuthGuard('jwt'))
  async startGame(
    @Body() body: { lobbyId: string },
    @Req() req: RequestWithUser,
  ) {
    const userId = req.user.id || req.user.userId;
    return this.gameService.startGame(body.lobbyId, userId);
  }

  @Post('guess')
  @UseGuards(AuthGuard('jwt'))
  async makeGuess(
    @Body() body: { lobbyId: string; guess: string },
    @Req() req: RequestWithUser,
  ) {
    const userId = req.user.id || req.user.userId;
    return this.gameService.makeGuess(body.lobbyId, userId, body.guess);
  }
}
