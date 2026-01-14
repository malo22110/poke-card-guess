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

    // Notify room of new player count and player list
    this.server.to(lobbyId).emit('playerUpdate', {
      count: status.players.length,
      playerList: status.players.map((p) => p.name),
    });
  }

  // --- Timer Helpers ---

  private async handleRoundTimeout(lobbyId: string) {
    const result = await this.gameService.forceEndRound(lobbyId);
    if (!result) return;

    this.server.to(lobbyId).emit('roundFinished', {
      winner: null,
      result: result,
      reason: 'timeout',
    });

    this.scheduleNextRound(lobbyId);
  }

  private scheduleNextRound(lobbyId: string) {
    setTimeout(async () => {
      const lobby = this.gameService.getLobby(lobbyId); // Fix: get lobby properly
      if (!lobby) return; // Fix: check for undefined

      const nextRoundData = await this.gameService.getCurrentRoundData(lobby); // Fix: await promise

      if (nextRoundData.status === 'FINISHED') {
        this.server.to(lobbyId).emit('nextRound', nextRoundData); // Send as nextRound so frontend handles it
        return;
      }

      this.server.to(lobbyId).emit('nextRound', nextRoundData);
      this.gameService.setRoundTimer(
        lobbyId,
        () => this.handleRoundTimeout(lobbyId),
        30000,
      );
    }, 3000);
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

      // Start timer for the first round
      this.gameService.setRoundTimer(
        data.lobbyId,
        () => this.handleRoundTimeout(data.lobbyId),
        30000,
      );
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
      this.server.to(data.lobbyId).emit('scoreboardUpdate', {
        scores: (result as any).scores,
        playerStatuses: (result as any).playerStatuses,
      });

      if ((result as any).correct && (result as any).roundFinished) {
        this.gameService.clearRoundTimer(data.lobbyId);

        this.server.to(data.lobbyId).emit('roundFinished', {
          winner: null,
          result: result,
        });

        this.scheduleNextRound(data.lobbyId);
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
      this.server.to(data.lobbyId).emit('scoreboardUpdate', {
        scores: (result as any).scores,
        playerStatuses: (result as any).playerStatuses,
      });

      if ((result as any).roundFinished) {
        this.gameService.clearRoundTimer(data.lobbyId);

        this.server.to(data.lobbyId).emit('roundFinished', {
          winner: null,
          result: result,
        });

        this.scheduleNextRound(data.lobbyId);
      }
    } catch (e) {
      client.emit('error', { message: e.message });
    }
  }
}
