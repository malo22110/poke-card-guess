import { Module } from '@nestjs/common';
import { TrophiesService } from './trophies.service';
import { TrophiesController } from './trophies.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [TrophiesController],
  providers: [TrophiesService, PrismaService],
  exports: [TrophiesService],
})
export class TrophiesModule {}
