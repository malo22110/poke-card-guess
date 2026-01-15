import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma.service';
import { TrophiesModule } from '../trophies/trophies.module';

import { UsersController } from './users.controller';

@Module({
  imports: [TrophiesModule],
  controllers: [UsersController],
  providers: [UsersService, PrismaService],
  exports: [UsersService],
})
export class UsersModule {}
