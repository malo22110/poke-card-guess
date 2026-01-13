import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { GameService } from './game.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly gameService: GameService) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    // Optional: Handle player disconnection (remove from lobby, etc.)
  }

  @SubscribeMessage('joinGame')
  joinGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lobbyId: string; userId: string; isHost?: boolean },
  ) {
    const { lobbyId, userId } = data;
    console.log(`User ${userId} joining lobby ${lobbyId} via WS`);

    // Join the socket.io room
    client.join(lobbyId);

    // Send current status immediately to the joining user
    const status = this.gameService.getLobbyStatus(lobbyId);
    client.emit('gameStatus', status);

    // Notify room of new player count
    this.server.to(lobbyId).emit('playerUpdate', {
      count: status.players,
    });
  }

  @SubscribeMessage('startGame')
  async startGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lobbyId: string; userId: string },
  ) {
    try {
      const result = await this.gameService.startGame(
        data.lobbyId,
        data.userId,
      );
      // Broadcast to EVERYONE in the lobby that the game has started
      this.server.to(data.lobbyId).emit('gameStarted', result);

      // Also emit updated status just in case
      this.server.to(data.lobbyId).emit('gameStatus', { status: 'PLAYING' });
    } catch (e) {
      client.emit('error', { message: e.message });
    }
  }

  @SubscribeMessage('makeGuess')
  async makeGuess(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lobbyId: string; userId: string; guess: string },
  ) {
    try {
      const result = await this.gameService.makeGuess(
        data.lobbyId,
        data.userId,
        data.guess,
      );
      client.emit('guessResult', result);

      if ((result as any).correct && (result as any).roundFinished) {
        // Only if EVERYONE is done do we end the round globally
        this.server.to(data.lobbyId).emit('roundFinished', {
          winner: null, // Logic changed: strict winner is less relevant in sync mode, or maybe last one?
          result: result,
        });

        const nextRoundData = this.gameService.getCurrentRoundData(
          this.gameService.getLobby(data.lobbyId),
        );
        setTimeout(() => {
          this.server.to(data.lobbyId).emit('nextRound', nextRoundData);
        }, 3000);
      }
    } catch (e) {
      client.emit('error', { message: e.message });
    }
  }

  @SubscribeMessage('giveUp')
  async giveUp(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lobbyId: string; userId: string },
  ) {
    try {
      const result = await this.gameService.giveUp(data.lobbyId, data.userId);

      // Emit individual result so the user sees the card
      client.emit('giveUpResult', result);

      if ((result as any).roundFinished) {
        this.server.to(data.lobbyId).emit('roundFinished', {
          winner: null,
          result: result,
        });

        const nextRoundData = this.gameService.getCurrentRoundData(
          this.gameService.getLobby(data.lobbyId),
        );

        setTimeout(() => {
          this.server.to(data.lobbyId).emit('nextRound', nextRoundData);
        }, 3000);
      }
    } catch (e) {
      client.emit('error', { message: e.message });
    }
  }
}
