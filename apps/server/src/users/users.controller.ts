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
}
