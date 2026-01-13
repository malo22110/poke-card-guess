import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class GameSocketService {
  static final GameSocketService _instance = GameSocketService._internal();
  late IO.Socket socket;
  
  // Stream controllers for events
  final _playerCountController = StreamController<int>.broadcast();
  final _gameStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _roundUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _guessResultController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<int> get playerCountStream => _playerCountController.stream;
  Stream<Map<String, dynamic>> get gameStatusStream => _gameStatusController.stream;
  Stream<Map<String, dynamic>> get gameStartedStream => _gameStartedController.stream;
  Stream<Map<String, dynamic>> get roundUpdateStream => _roundUpdateController.stream;
  Stream<Map<String, dynamic>> get guessResultStream => _guessResultController.stream;

  factory GameSocketService() {
    return _instance;
  }

  GameSocketService._internal() {
    _initSocket();
  }

  void _initSocket() {
    // Replace with your actual server URL
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Connected to generic socket');
    });

    socket.on('playerUpdate', (data) {
      if (data != null && data['count'] != null) {
        _playerCountController.add(data['count']);
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
}
