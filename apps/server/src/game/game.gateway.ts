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

  private progressiveRevealIntervals: Map<string, NodeJS.Timeout> = new Map();
  private clientData: Map<string, { lobbyId: string; userId: string }> =
    new Map();
  private emptyLobbyTimers: Map<string, NodeJS.Timeout> = new Map();

  constructor(private readonly gameService: GameService) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    const data = this.clientData.get(client.id);
    if (!data) return;

    this.clientData.delete(client.id);
    const { lobbyId } = data;

    // Check if any sockets remain in this lobby
    const sockets = await this.server.in(lobbyId).fetchSockets();
    if (sockets.length === 0) {
      console.log(`[Lobby] ${lobbyId} is empty. Scheduling deletion in 15s...`);
      const timer = setTimeout(() => {
        this.gameService.deleteLobby(lobbyId);
        this.stopProgressiveReveal(lobbyId);
        this.emptyLobbyTimers.delete(lobbyId);
      }, 15_000);
      this.emptyLobbyTimers.set(lobbyId, timer);
    }
  }

  @SubscribeMessage('joinGame')
  joinGame(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { lobbyId: string; userId: string; isHost?: boolean },
  ) {
    const { lobbyId, userId } = data;
    console.log(`User ${userId} joining lobby ${lobbyId} via WS`);

    // Track this socket -> lobby mapping
    this.clientData.set(client.id, { lobbyId, userId });

    // If a deletion timer was pending for this lobby, cancel it
    const pending = this.emptyLobbyTimers.get(lobbyId);
    if (pending) {
      clearTimeout(pending);
      this.emptyLobbyTimers.delete(lobbyId);
      console.log(`[Lobby] ${lobbyId} deletion aborted — player reconnected.`);
    }

    // Join the socket.io room
    client.join(lobbyId);

    // Send current status immediately to the joining user
    const status = this.gameService.getLobbyStatus(lobbyId);
    client.emit('gameStatus', status);

    // Notify room of new player count and player list
    this.server.to(lobbyId).emit('playerUpdate', {
      count: status.players.length,
      playerList: status.players.map((p) => p.name),
      playerPictures: Object.fromEntries(
        status.players.map((p) => [p.name, p.picture]),
      ),
    });
  }

  // --- Timer Helpers ---

  private async handleRoundTimeout(lobbyId: string) {
    const result = await this.gameService.forceEndRound(lobbyId);
    if (!result) return;

    // Stop progressive reveal when round ends
    this.stopProgressiveReveal(lobbyId);

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

      // Set round start time RIGHT BEFORE sending data to clients
      lobby.roundStartTime = Date.now();

      this.server.to(lobbyId).emit('nextRound', nextRoundData);

      // Start progressive reveal for this round
      this.startProgressiveReveal(lobbyId);

      this.gameService.setRoundTimer(
        lobbyId,
        () => this.handleRoundTimeout(lobbyId),
        30000,
      );
    }, 3000);
  }

  private startProgressiveReveal(lobbyId: string) {
    // Clear any existing interval
    this.stopProgressiveReveal(lobbyId);

    // Emit progressive reveals every 500ms for smooth animation
    const interval = setInterval(async () => {
      const revealData = await this.gameService.getProgressiveReveal(lobbyId);
      if (revealData) {
        this.server.to(lobbyId).emit('progressiveReveal', revealData);
      } else {
        // Stop if lobby is no longer active
        this.stopProgressiveReveal(lobbyId);
      }
    }, 500);

    this.progressiveRevealIntervals.set(lobbyId, interval);
  }

  private stopProgressiveReveal(lobbyId: string) {
    const interval = this.progressiveRevealIntervals.get(lobbyId);
    if (interval) {
      clearInterval(interval);
      this.progressiveRevealIntervals.delete(lobbyId);
    }
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

      // Start progressive reveal for the first round
      this.startProgressiveReveal(data.lobbyId);

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

        // Stop progressive reveal when round ends
        this.stopProgressiveReveal(data.lobbyId);

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

        // Stop progressive reveal when round ends
        this.stopProgressiveReveal(data.lobbyId);

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
