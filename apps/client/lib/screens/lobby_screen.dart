import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/footer.dart';

class LobbyScreen extends StatefulWidget {
  final String? authToken;
  const LobbyScreen({super.key, this.authToken});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _lobbyIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _guestName;
  String? _guestAvatar;

  double _rounds = 10;
  bool _secretOnly = true;
  final TextEditingController _setIdController = TextEditingController(text: '151');

  String? _userName;

  @override
  void initState() {
    super.initState();
    if (widget.authToken != null) {
      _fetchUserProfile();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['name'];
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args.containsKey('guestName')) {
        setState(() {
          _guestName = args['guestName'];
        });
      }
      if (args.containsKey('guestAvatar')) {
        _guestAvatar = args['guestAvatar'];
      }
    }
  }

  Future<void> _createGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode(
          {
            'rounds': _rounds.toInt(),
            'sets': [_setIdController.text.trim()],
            'secretOnly': _secretOnly,
            'guestName': _guestName ?? _userName,
          }
        ),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final lobbyId = data['id'];
        final hostId = data['hostId'];
        _navigateToGame(lobbyId, isHost: true, guestId: hostId);
      } else {
        throw Exception('Failed to create game: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGame() async {
    final lobbyId = _lobbyIdController.text.trim().toUpperCase();
    if (lobbyId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'lobbyId': lobbyId,
          'guestName': _guestName,
          'guestAvatar': _guestAvatar,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final guestId = data['guestId']; // Extract guestId from join response
        
        final uri = Uri(path: '/waiting-room', queryParameters: {
          'lobbyId': lobbyId,
          'isHost': 'false',
          if (guestId != null) 'guestId': guestId.toString(),
        });
        Navigator.of(context).pushNamed(
          uri.toString(), 
          arguments: {
            'authToken': widget.authToken,
            'guestName': _guestName,
            'guestAvatar': _guestAvatar,
          }
        );
      } else {
        throw Exception('Failed to join game: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToGame(String lobbyId, {required bool isHost, String? guestId}) {
    final uri = Uri(path: '/waiting-room', queryParameters: {
      'lobbyId': lobbyId,
      'isHost': isHost.toString(),
    });
    Navigator.of(context).pushNamed(
      uri.toString(),
      arguments: {
        'authToken': widget.authToken,
        'guestName': _guestName,
        'guestAvatar': _guestAvatar,
      }
    );
  }

  void _showCreateGameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a237e),
              title: const Text('Game Configuration', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rounds', style: TextStyle(color: Colors.white70)),
                    Slider(
                      value: _rounds,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: _rounds.round().toString(),
                      onChanged: (value) => setState(() => _rounds = value),
                    ),
                    Text('${_rounds.round()} Rounds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Secret Cards Only', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _secretOnly,
                          onChanged: (value) => setState(() => _secretOnly = value),
                          activeColor: Colors.amber,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _setIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Card Set ID (e.g. 151, base1)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createGame();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  child: const Text('Start Game'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'POKÉ CARD GUESS',
        userName: _guestName ?? _userName,
        onProfilePressed: () {
          Navigator.of(context).pushNamed('/profile', arguments: {'authToken': widget.authToken});
        },
      ),
      drawer: AppDrawer(authToken: widget.authToken),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/landscape.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: kToolbarHeight + 16),
                  Image.asset(
                    'assets/images/pokecardguess.png',
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 48),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Text(
                          _error!, 
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pushNamed('/create-game', arguments: {
                          'authToken': widget.authToken,
                          'guestName': _guestName,
                          'guestAvatar': _guestAvatar,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create New Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _lobbyIdController,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        hintText: 'Enter Lobby ID to Join',
                        hintStyle: const TextStyle(color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 3),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      cursorColor: const Color(0xFF3B4CCA),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _joinGame,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.5)),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Join Game'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
  bottomNavigationBar: const GameFooter(),
);
  }
}
