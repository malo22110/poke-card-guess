import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

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

  double _rounds = 10;
  bool _secretOnly = true;
  final TextEditingController _setIdController = TextEditingController(text: '151');

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
          }
        ),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final lobbyId = data['id'];
        _navigateToGame(lobbyId, isHost: true);
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
        body: jsonEncode({'lobbyId': lobbyId}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final guestId = data['guestId']; // Extract guestId from join response
        
        Navigator.of(context).pushNamed('/waiting-room', arguments: {
          'lobbyId': lobbyId,
          'isHost': false,
          'authToken': widget.authToken,
          'guestId': guestId, // Pass the joined user's guestId (if they are a guest)
        });
      } else {
        throw Exception('Failed to join game: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToGame(String lobbyId, {required bool isHost}) {
    Navigator.of(context).pushNamed('/waiting-room', arguments: {
      'lobbyId': lobbyId,
      'isHost': isHost,
      'authToken': widget.authToken,
      // 'guestId': ... we need this if we are a guest joining!
    });
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.catching_pokemon, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      'PokeCard Guess',
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

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
                          'authToken': widget.authToken
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        hintText: 'Enter Lobby ID to Join',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
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
            ),
          ),
        ),
      ),
    );
  }
}
