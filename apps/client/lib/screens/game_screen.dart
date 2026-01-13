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
  String? _gameId;
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

  String? _authToken;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _guessController = TextEditingController();
    _checkAuth();
    startNewGame();
  }

  // --- Auth Logic ---
  void _checkAuth() {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('token')) {
      setState(() {
        _authToken = uri.queryParameters['token'];
      });
      debugPrint('Logged in with token: $_authToken');
    }
  }

  Future<void> _login() async {
    final url = Uri.parse('http://localhost:3000/auth/google');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_self');
    }
  }

  void _logout() {
    setState(() {
      _authToken = null;
    });
  }
  // --- End Auth Logic ---

  Future<void> startNewGame() async {
    setState(() {
      _isLoading = true;
      showFullCard = false;
      error = null;
      _isCorrect = null;
      _guessController.clear();
      _gameId = null;
      _croppedImage = null;
      _fullImageUrl = null;
      _revealedName = null;
      _revealedSet = null;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/game/start'));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        String croppedImage = data['croppedImage'];
        if (croppedImage.contains(',')) {
          croppedImage = croppedImage.split(',').last;
        }
        
        setState(() {
          _gameId = data['gameId'];
          _croppedImage = croppedImage;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to start game: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Failed to start game: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> checkGuess() async {
    if (_gameId == null || _guessController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/guess'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameId': _gameId,
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
    if (_gameId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/give-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameId': _gameId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          showFullCard = true;
          _isCorrect = false;
          _fullImageUrl = result['fullImageUrl'];
          _revealedName = result['name'];
          _revealedSet = result['set'];
          attempts++;
        });
      }
    } catch (e) {
      print('Error giving up: $e');
    }
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
