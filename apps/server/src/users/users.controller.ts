import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Assuming this exists or will be created/imported correctly
import { User } from '@prisma/client';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

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
    @Body() body: { name?: string; picture?: string }, // Add more validation in real app
  ): Promise<User> {
    const userId = req.user.userId;

    // Determine if profile is becoming complete
    // Simple logic: if name is present, we consider it complete or at least "set up"
    // Ideally we validata fields.

    const updateData: any = {
      ...body,
      profileCompleted: true, // Mark as complete on first update
    };

    return this.usersService.update(userId, updateData);
  }
}
