import { Controller, Get, Post, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TrophiesService } from './trophies.service';

@Controller('trophies')
export class TrophiesController {
  constructor(private readonly trophiesService: TrophiesService) {}

  @Get()
  async getAllTrophies() {
    return this.trophiesService.getAllTrophies();
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyTrophies(@Request() req) {
    return this.trophiesService.getUserTrophies(req.user.userId);
  }

  @Post('check')
  @UseGuards(JwtAuthGuard)
  async checkTrophies(@Request() req) {
    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      req.user.userId,
    );
    return {
      newTrophies,
      count: newTrophies.length,
    };
  }
}
