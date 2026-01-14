import { Module } from '@nestjs/common';
import { GameModesService } from './game-modes.service';
import { GameModesController } from './game-modes.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [GameModesController],
  providers: [GameModesService, PrismaService],
  exports: [GameModesService],
})
export class GameModesModule {}
