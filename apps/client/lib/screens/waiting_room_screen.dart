import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokecardguess/config/app_config.dart';
import '../services/game_socket_service.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';

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
  StreamSubscription? _playerListSub;
  StreamSubscription? _playerPicturesSub;
  StreamSubscription? _statusSub;

  int _playerCount = 1;
  List<String> _playerList = [];
  Map<String, String?> _playerPictures = {}; // name -> picture URL
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  Map<String, dynamic>? _gameConfig;

  String? _guestName;
  String? _userName;

  @override
  void initState() {
    super.initState();
    // Socket init moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args['lobbyId'] != null) {
      if (!_isInitialized) {
        _isInitialized = true;
        lobbyId = args['lobbyId'];
        isHost = args['isHost'] == true || args['isHost'] == 'true';
        authToken = args['authToken'];
        guestId = args['guestId']; 
        _guestName = args['guestName']; // Read guestName

        if (authToken != null && _userName == null) {
          _fetchUserProfile().then((_) => _joinGameApi());
        } else {
          _joinGameApi();
        }
      }
    } else {
      lobbyId = '';
      isHost = false;
      // Redirect to lobby if accessed without ID
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/lobby');
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['name'];
          });
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _fetchLobbyDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/game/$lobbyId/status'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _gameConfig = data;
            // Status endpoint returns players: [{id, name, picture}]
            if (data['players'] != null) {
              final players = data['players'] as List;
              _playerList = players.map((p) => p['name'].toString()).toList();
              for (final p in players) {
                final name = p['name'].toString();
                final pic = p['picture'] as String?;
                if (pic != null) _playerPictures[name] = pic;
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching lobby details: $e');
    }
  }

  Future<void> _joinGameApi() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/game/join'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'lobbyId': lobbyId,
          'guestId': guestId, // Send guestId if available
          'guestName': _guestName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully joined, now initialize socket and fetch details
        _initSocket();
        _fetchLobbyDetails();
      } else {
        setState(() => _error = 'Failed to join game: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Error joining game: $e');
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
      if (mounted) {
        setState(() => _playerCount = count);
      }
    });

    _playerListSub = _socketService.playerListStream.listen((list) {
      if (mounted) {
        setState(() {
          _playerList = list;
        });
      }
    });

    _playerPicturesSub = _socketService.playerPicturesStream.listen((pics) {
      if (mounted) {
        setState(() {
          _playerPictures = pics;
        });
      }
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
    _playerListSub?.cancel();
    _playerPicturesSub?.cancel();
    _statusSub?.cancel();
    // Do not disconnect socket service here as GameScreen needs it?
    // Actually GameScreen might need it. Let's keep it connected.
    super.dispose();
  }

  Future<void> _startGame() async {
    if (lobbyId.isEmpty || !isHost) return;
    // Notify server via WS
    _socketService.startGame(lobbyId, guestId ?? 'host');
  }

  void _copyJoinLink() {
    final joinUrl = '${AppConfig.clientUrl}/#/join?lobbyId=$lobbyId';
    Clipboard.setData(ClipboardData(text: joinUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('Invite link copied: $joinUrl', style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: const Color(0xFF1a237e),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToGame() {
    final uri = Uri(path: '/game', queryParameters: {
      'lobbyId': lobbyId,
      'isHost': isHost.toString(),
      if (guestId != null) 'guestId': guestId.toString(),
    });

    Navigator.of(context).pushReplacementNamed(
      uri.toString(), 
      arguments: {'authToken': authToken}
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'WAITING ROOM', 
        userName: _guestName ?? _userName,
        onProfilePressed: () {
             Navigator.of(context).pushNamed('/profile', arguments: {'authToken': authToken});
        },
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: kToolbarHeight),
                  Text(
                    'Lobby: ${lobbyId.isEmpty ? "Loading..." : lobbyId}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  
                  // Invite Link Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Material(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _copyJoinLink,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Invite Link',
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                    Text(
                                      '${AppConfig.clientUrl}/#/join?lobbyId=$lobbyId',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.copy, color: Colors.amber, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.people, size: 32, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          '$_playerCount Player(s) Joined',
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        if (_playerList.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _playerList.map((playerName) {
                               final isMe = (playerName == _guestName || playerName == _userName);
                               final picUrl = _playerPictures[playerName];
                               final resolvedUrl = picUrl == null
                                   ? null
                                   : picUrl.startsWith('http')
                                       ? picUrl
                                       : '${AppConfig.apiBaseUrl}$picUrl';
                               return Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: isMe ? Colors.amber : Colors.indigo.shade900,
                                    backgroundImage: resolvedUrl != null
                                        ? CachedNetworkImageProvider(resolvedUrl)
                                        : null,
                                    child: resolvedUrl == null
                                        ? Text(playerName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10))
                                        : null,
                                  ),
                                  label: Text(
                                      isMe ? 'You ($playerName)' : playerName,
                                      style: TextStyle(
                                        fontSize: 14, 
                                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal
                                      )
                                  ),
                                  backgroundColor: isMe ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.9),
                                  side: isMe ? const BorderSide(color: Colors.amber) : null,
                               );
                             }).toList(),
                          )
                        else
                          const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)
                          ),
                        const SizedBox(height: 16),
                         const Text(
                          'Waiting for others...',
                          style: TextStyle(fontSize: 14, color: Colors.white54, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_gameConfig != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          const Text('Game Configuration', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildConfigRow('Rounds', '${_gameConfig!['config']['rounds']}'),
                          _buildConfigRow('Sets', '${(_gameConfig!['config']['sets'] as List).join(', ')}'),
                          _buildConfigRow('Secret Only', '${_gameConfig!['config']['secretOnly'] ? 'Yes' : 'No'}'),
                          if (_gameConfig!['config']['rarities'] != null)
                             _buildConfigRow('Rarities', '${(_gameConfig!['config']['rarities'] as List).length} selected'),
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
              );
            },
          ),
        ),
      ),
    );
  }


  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
