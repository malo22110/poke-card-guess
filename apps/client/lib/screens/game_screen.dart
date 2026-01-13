import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/game/game_header.dart';
import '../widgets/game/card_display.dart';
import '../widgets/game/guess_input.dart';
import '../widgets/game/result_display.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _lobbyId;
  String? _gameId; // Current round ID or similar
  String? _authToken;
  bool _isHost = false;

  String? _croppedImage;
  String? _fullImageUrl;
  String? _revealedName;
  String? _revealedSet;

  bool _isLoading = true;
  bool showFullCard = false;
  String? error;
  int score = 0;
  int attempts = 0;
  late TextEditingController _guessController;
  bool? _isCorrect;
  
  @override
  void initState() {
    super.initState();
    _guessController = TextEditingController();
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _lobbyId = args['lobbyId'];
      _isHost = args['isHost'] ?? false;
      _authToken = args['authToken'];
      // Only start game if we haven't already and have the necessary data
      if (_gameId == null) {
        startNewGame();
      }
    }
  }

  // --- Auth Logic Removed (Handled in Main/Lobby) ---

  Future<void> startNewGame() async {
    if (_lobbyId == null || _authToken == null) return;

    setState(() {
      _isLoading = true;
      showFullCard = false;
      error = null;
      _isCorrect = null;
      _guessController.clear();
      _croppedImage = null;
      _fullImageUrl = null;
      _revealedName = null;
      _revealedSet = null;
    });

    try {
      // If host, trigger start. If guest, we should probably just 'get state', 
      // but for this MVP 'start' endpoint acts as 'get current round' too if game is playing.
      // Re-using the /game/start endpoint which logic is now: fetch current round data.
      
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'lobbyId': _lobbyId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'FINISHED') {
           setState(() {
             error = 'Game Finished!';
             _isLoading = false;
           });
           return;
        }

        if (data['status'] == 'WAITING') {
          // Poll again in 2 seconds
          await Future.delayed(const Duration(seconds: 2));
           if (mounted) startNewGame();
           return;
        }

        String croppedImage = data['croppedImage'];
        if (croppedImage.contains(',')) {
          croppedImage = croppedImage.split(',').last;
        }
        
        setState(() {
          _gameId = data['gameId']; // Uses Lobby ID effectively
          _croppedImage = croppedImage;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load game round: ${response.body}');
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load game: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> checkGuess() async {
    if (_lobbyId == null || _guessController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/guess'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'lobbyId': _lobbyId,
          'guess': _guessController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isCorrect = data['correct'];
          if (_isCorrect == true) {
            _fullImageUrl = data['fullImageUrl'];
            _revealedName = data['name'];
            _revealedSet = data['set'];
            showFullCard = true;
            error = null;
            score++;
            attempts++;
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect! Try again.')),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking guess: $e')),
      );
    }
  }

  Future<void> giveUp() async {
    // TODO: Implement give up for Lobby mode (maybe skip vote?)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Give up not yet implemented for multiplayer mode.')),
    );
  }

  void nextCard() {
    startNewGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a237e),
              const Color(0xFF3B4CCA),
              const Color(0xFF5E35B1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              GameHeader(score: score, attempts: attempts),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? _buildLoadingState()
                      : error != null
                          ? _buildErrorState()
                          : _buildGameContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading Pokemon card...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red.withOpacity(0.7),
        ),
        const SizedBox(height: 16),
        Text(
          error ?? 'An error occurred',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: startNewGame,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3B4CCA),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent() {
    if (_croppedImage == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CardDisplay(
              showFullCard: showFullCard,
              croppedImage: _croppedImage,
              fullImageUrl: _fullImageUrl,
            ),
            const SizedBox(height: 24),
            if (!showFullCard)
              GuessInput(
                controller: _guessController,
                onGuessSubmitted: checkGuess,
                onGiveUp: giveUp,
              )
            else
              ResultDisplay(
                isCorrect: _isCorrect,
                revealedName: _revealedName,
                revealedSet: _revealedSet,
                onNextCard: nextCard,
              ),
          ],
        ),
      ),
    );
  }
}
