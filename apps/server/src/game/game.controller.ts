import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { GameService } from './game.service';

@Controller('game')
export class GameController {
  constructor(private readonly gameService: GameService) {}

  @Get('start')
  async startGame() {
    return this.gameService.startGame();
  }

  @Post('guess')
  async makeGuess(@Body() body: { gameId: string; guess: string }) {
    return this.gameService.makeGuess(body.gameId, body.guess);
  }

  @Post('give-up')
  async giveUp(@Body() body: { gameId: string }) {
    return this.gameService.giveUp(body.gameId);
  }

  @Post('save')
  @UseGuards(AuthGuard('jwt'))
  async saveGame(
    @Body() body: { gameId: string; correct: boolean },
    @Req() req,
  ) {
    return this.gameService.saveGame(
      req.user.userId,
      body.gameId,
      body.correct,
    );
  }
}
