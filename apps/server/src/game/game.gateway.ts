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

      if (result.correct) {
        // If correct, broadcast to everyone that round changed (optional, or just for the winner?)
        // Usually, if one person guesses right, everyone moves to next card?
        // OR is it individual score?
        // Based on current logic: "Advance round" is on the lobby. So everyone moves.

        const nextRoundData = this.gameService.getCurrentRoundData(
          this.gameService.getLobby(data.lobbyId),
        );
        // Delay slightly to let them see the "Correct" message/animation?
        // Or send "RoundFinished" event

        this.server.to(data.lobbyId).emit('roundFinished', {
          winner: data.userId,
          result: result, // contains revealed card info
        });

        // Send next round data after a delay
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

      this.server.to(data.lobbyId).emit('roundFinished', {
        winner: null, // No winner on give up
        result: result,
      });

      const nextRoundData = this.gameService.getCurrentRoundData(
        this.gameService.getLobby(data.lobbyId),
      );

      setTimeout(() => {
        this.server.to(data.lobbyId).emit('nextRound', nextRoundData);
      }, 3000);
    } catch (e) {
      client.emit('error', { message: e.message });
    }
  }
}
