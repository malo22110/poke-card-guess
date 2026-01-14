import { Module } from '@nestjs/common';
import { TrophiesService } from './trophies.service';
import { TrophiesController } from './trophies.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TrophiesController],
  providers: [TrophiesService],
  exports: [TrophiesService],
})
export class TrophiesModule {}
