import { Module } from '@nestjs/common';
import { GameController } from './game.controller';
import { GameService } from './game.service';
import { PrismaService } from '../prisma.service';

import { GameGateway } from './game.gateway';

@Module({
  controllers: [GameController],
  providers: [GameService, PrismaService, GameGateway],
})
export class GameModule {}
