import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { TrophiesService } from '../trophies/trophies.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Assuming this exists or will be created/imported correctly
import { User } from '@prisma/client';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly trophiesService: TrophiesService,
  ) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req): Promise<User> {
    const userId = req.user.userId;
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  @UseGuards(JwtAuthGuard)
  @Patch('profile')
  async updateProfile(
    @Request() req,
    @Body()
    body: { name?: string; picture?: string; socials?: Record<string, string> },
  ): Promise<User> {
    const userId = req.user.userId;

    const updateData: any = {
      ...body,
      profileCompleted: true,
    };

    if (body.socials) {
      updateData.socials = JSON.stringify(body.socials);
    }

    return this.usersService.update(userId, updateData);
  }

  @UseGuards(JwtAuthGuard)
  @Post('share')
  async trackShare(
    @Request() req,
  ): Promise<{ success: boolean; totalShares: number; newTrophies?: any[] }> {
    const userId = req.user.userId;
    const user = await this.usersService.incrementShareCount(userId);

    // Check for social trophies
    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      userId,
      { category: 'social' },
    );

    return {
      success: true,
      totalShares: user.sharesCount,
      newTrophies,
    };
  }

  @Post('donation')
  async recordDonation(
    @Request() req,
    @Body() body: { amount: number }, // Amount in dollars
  ): Promise<{ success: boolean; totalDonated: number; newTrophies: any[] }> {
    const userId = req.user.userId;
    const amountInCents = Math.round(body.amount * 100);
    const user = await this.usersService.addDonation(userId, amountInCents);

    // Check for donation trophies
    const newTrophies = await this.trophiesService.checkAndAwardTrophies(
      userId,
      { category: 'donation' },
    );

    return {
      success: true,
      totalDonated: user.totalDonated / 100, // Return in dollars
      newTrophies,
    };
  }
}
