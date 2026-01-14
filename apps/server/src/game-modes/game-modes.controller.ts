import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { GameModesService } from './game-modes.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('gamemodes')
export class GameModesController {
  constructor(private readonly gameModesService: GameModesService) {}

  @Get()
  findAll() {
    return this.gameModesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.gameModesService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Request() req, @Body() body: any) {
    return this.gameModesService.create({
      ...body,
      creatorId: req.user.userId,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/upvote')
  upvote(@Request() req, @Param('id') id: string) {
    return this.gameModesService.upvote(id, req.user.userId);
  }

  @Get(':id/leaderboard')
  getLeaderboard(@Param('id') id: string) {
    return this.gameModesService.getLeaderboard(id);
  }
}
