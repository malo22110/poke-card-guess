import { Controller, Get, Post, Body, Query } from '@nestjs/common';
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
}
