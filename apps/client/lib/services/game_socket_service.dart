import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:pokecardguess/config/app_config.dart';

class GameSocketService {
  static final GameSocketService _instance = GameSocketService._internal();
  late IO.Socket socket;
  
  // Stream controllers for events
  final _playerCountController = StreamController<int>.broadcast();
  final _playerListController = StreamController<List<String>>.broadcast();
  final _gameStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _roundUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _guessResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _scoreboardUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _roundFinishedController = StreamController<Map<String, dynamic>>.broadcast();
  final _giveUpResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _progressiveRevealController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<int> get playerCountStream => _playerCountController.stream;
  Stream<List<String>> get playerListStream => _playerListController.stream;
  Stream<Map<String, dynamic>> get gameStatusStream => _gameStatusController.stream;
  Stream<Map<String, dynamic>> get gameStartedStream => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get roundUpdateStream => _roundUpdateController.stream;
  Stream<Map<String, dynamic>> get guessResultStream => _guessResultController.stream;
  Stream<Map<String, dynamic>> get scoreboardUpdateStream => _scoreboardUpdateController.stream;
  Stream<Map<String, dynamic>> get roundFinishedStream => _roundFinishedController.stream;
  Stream<Map<String, dynamic>> get giveUpResultStream => _giveUpResultController.stream;
  Stream<Map<String, dynamic>> get progressiveRevealStream => _progressiveRevealController.stream;

  factory GameSocketService() {
    return _instance;
  }

  GameSocketService._internal() {
    _initSocket();
  }

  void _initSocket() {
    // Replace with your actual server URL
    socket = IO.io(AppConfig.socketBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Connected to generic socket');
    });

    socket.on('playerUpdate', (data) {
      if (data != null) {
        if (data['count'] != null) {
          _playerCountController.add(data['count']);
        }
        if (data['playerList'] != null) {
          _playerListController.add(List<String>.from(data['playerList']));
        }
      }
    });

    socket.on('gameStatus', (data) {
       _gameStatusController.add(Map<String, dynamic>.from(data));
    });

    socket.on('gameStarted', (data) {
      _gameStartedController.add(Map<String, dynamic>.from(data));
    });

    socket.on('nextRound', (data) {
      _roundUpdateController.add(Map<String, dynamic>.from(data));
    });
    
    socket.on('guessResult', (data) {
      _guessResultController.add(Map<String, dynamic>.from(data));
    });

    socket.on('scoreboardUpdate', (data) {
      _scoreboardUpdateController.add(Map<String, dynamic>.from(data));
    });

    socket.on('roundFinished', (data) {
      _roundFinishedController.add(Map<String, dynamic>.from(data));
    });

    socket.on('giveUpResult', (data) {
      _giveUpResultController.add(Map<String, dynamic>.from(data));
    });

    socket.on('progressiveReveal', (data) {
      _progressiveRevealController.add(Map<String, dynamic>.from(data));
    });

    socket.onDisconnect((_) => print('Disconnected'));
  }

  void connect() {
    if (!socket.connected) {
      socket.connect();
    }
  }

  void disconnect() {
    socket.disconnect();
  }

  void joinGame(String lobbyId, String userId) {
    socket.emit('joinGame', {'lobbyId': lobbyId, 'userId': userId});
  }

  void startGame(String lobbyId, String userId) {
    socket.emit('startGame', {'lobbyId': lobbyId, 'userId': userId});
  }
  
  void makeGuess(String lobbyId, String userId, String guess) {
    socket.emit('makeGuess', {'lobbyId': lobbyId, 'userId': userId, 'guess': guess});
  }

  void giveUp(String lobbyId, String userId) {
    socket.emit('giveUp', {'lobbyId': lobbyId, 'userId': userId});
  }
}
