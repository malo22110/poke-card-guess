import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_socket_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late String lobbyId;
  late bool isHost;
  String? authToken;
  String? guestId;

  final _socketService = GameSocketService();
  StreamSubscription? _playerCountSub;
  StreamSubscription? _statusSub;

  int _playerCount = 1;
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      lobbyId = args['lobbyId'];
      isHost = args['isHost'];
      authToken = args['authToken'];
      guestId = args['guestId']; 

      _initSocket();
    }
  }
  
  void _initSocket() {
    _socketService.connect();
    
    // Join the game via WebSocket
    final userId = authToken != null ? 'user-from-token-placeholder' : (guestId ?? 'guest');
    // Note: If using token, we might need to decode it or backend handles it via handshake auth.
    // For now, simpler: we pass the ID we know. Guest ID is crucial.
    // Ideally authToken shouldn't be decoded here. 
    // Let's assume guestId is populated or we rely on backend to identify from connection if strictly token based authentication was set up for WS.
    // Current GateWay implementation expects { userId }.
    
    _socketService.joinGame(lobbyId, guestId ?? 'unknown');

    _playerCountSub = _socketService.playerCountStream.listen((count) {
      if (mounted) setState(() => _playerCount = count);
    });

    bool navigationTriggered = false;

    _statusSub = _socketService.gameStatusStream.listen((data) {
       if (data['status'] == 'PLAYING' && !navigationTriggered) {
         navigationTriggered = true;
         _navigateToGame();
       }
    });

    _socketService.gameStartedStream.listen((data) {
       if (!navigationTriggered) {
          navigationTriggered = true;
          _navigateToGame();
       }
    });
  }

  @override
  void dispose() {
    _playerCountSub?.cancel();
    _statusSub?.cancel();
    // Do not disconnect socket service here as GameScreen needs it?
    // Actually GameScreen might need it. Let's keep it connected.
    super.dispose();
  }

  Future<void> _startGame() async {
    if (!isHost) return;
    // Notify server via WS
    _socketService.startGame(lobbyId, guestId ?? 'host');
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacementNamed('/game', arguments: {
      'lobbyId': lobbyId,
      'isHost': isHost,
      'authToken': authToken,
      'guestId': guestId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lobby: ${lobbyId}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                  const SizedBox(height: 48),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.people, size: 48, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          '$_playerCount Player(s) Joined',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                         const Text(
                          'Waiting for others...',
                          style: TextStyle(fontSize: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  if (_error != null)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                     ),

                  if (isHost)
                    ElevatedButton(
                      onPressed: _isLoading && _playerCount == 0 ? null : _startGame, // Allow start immediately if desired
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('START GAME'),
                    )
                  else
                    Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        const Text('Waiting for host to start...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    
                  const SizedBox(height: 24),
                  if (isHost) // Logic to copy invite code could go here
                     OutlinedButton.icon(
                      onPressed: () {
                         Clipboard.setData(ClipboardData(text: lobbyId));
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Lobby ID copied to clipboard!')),
                         );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Lobby ID'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
