import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GameModule } from './game/game.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { GameModesModule } from './game-modes/game-modes.module';
import { TrophiesModule } from './trophies/trophies.module';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    GameModule,
    UsersModule,
    AuthModule,
    GameModesModule,
    TrophiesModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
