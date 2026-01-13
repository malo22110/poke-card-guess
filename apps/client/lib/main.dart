import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokeCardGuessApp());
}

class PokeCardGuessApp extends StatelessWidget {
  const PokeCardGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Card Guess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B4CCA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CardGuessGame(),
    );
  }
}

class CardGuessGame extends StatefulWidget {
  const CardGuessGame({super.key});

  @override
  State<CardGuessGame> createState() => _CardGuessGameState();
}

class _CardGuessGameState extends State<CardGuessGame> {
  String? gameId;
  Uint8List? croppedImageBytes;
  String? fullImageUrl;
  String? revealedName;
  String? revealedSet;
  
  bool isLoading = true;
  bool showFullCard = false;
  String? error;
  int score = 0;
  int attempts = 0;
  late TextEditingController _guessController;
  bool? isCorrect;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _guessController = TextEditingController();
    startNewGame();
  }

  Future<void> startNewGame() async {
    setState(() {
      isLoading = true;
      showFullCard = false;
      error = null;
      isCorrect = null;
      _guessController.clear();
      gameId = null;
      croppedImageBytes = null;
      fullImageUrl = null;
      revealedName = null;
      revealedSet = null;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/game/start'));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Image = data['croppedImage'].split(',').last; // Remove data:image/png;base64, prefix if present
        
        setState(() {
          gameId = data['gameId'];
          croppedImageBytes = base64Decode(base64Image);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to start game: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Failed to start game: $e';
        isLoading = false;
      });
    }
  }

  Future<void> checkGuess() async {
    if (gameId == null || _guessController.text.isEmpty) return;

    final guess = _guessController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/guess'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gameId': gameId,
          'guess': guess,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['correct'] == true) {
          setState(() {
            isCorrect = true;
            showFullCard = true;
            fullImageUrl = result['fullImageUrl'];
            revealedName = result['name'];
            revealedSet = result['set'];
            score++;
            attempts++;
          });
        } else {
          setState(() {
            isCorrect = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Not quite! Try again.'),
              backgroundColor: Colors.red.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking guess: $e')),
      );
    }
  }

  Future<void> giveUp() async {
    if (gameId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/give-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'gameId': gameId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          showFullCard = true;
          isCorrect = false;
          fullImageUrl = result['fullImageUrl'];
          revealedName = result['name'];
          revealedSet = result['set'];
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
              _buildHeader(),
              Expanded(
                child: Center(
                  child: isLoading
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PokeCard Guess',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Guess the Pokemon!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Score: $score/$attempts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    if (croppedImageBytes == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCardDisplay(),
            const SizedBox(height: 24),
            if (!showFullCard) ...[
              _buildGuessInput(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ] else ...[
              _buildResultMessage(),
              _buildCardInfo(),
              const SizedBox(height: 16),
              _buildNextButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuessInput() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextField(
        controller: _guessController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Who\'s that Pokemon?',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: checkGuess,
          ),
        ),
        onSubmitted: (_) => checkGuess(),
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: checkGuess,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: const Color(0xFF1a237e),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Submit Guess'),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: giveUp,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Give Up'),
        ),
      ],
    );
  }

  Widget _buildResultMessage() {
    if (isCorrect == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        isCorrect! ? 'Correct! It\'s $revealedName!' : 'Nice try! It was $revealedName.',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isCorrect! ? Colors.greenAccent : Colors.orangeAccent,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCardDisplay() {
    return Hero(
      tag: 'card_display',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (!showFullCard)
                  _buildCroppedCard()
                else
                  _buildFullCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCroppedCard() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Show the cropped image at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.memory(
              croppedImageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, size: 50),
                  ),
                );
              },
            ),
          ),
          // Gradient overlay at the top to create mystery effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 150, // Leave space for the cropped image
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1a237e),
                    const Color(0xFF1a237e).withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 80,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Who\'s that Pokemon?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    if (fullImageUrl == null) return const SizedBox.shrink();
    
    return Image.network(
      fullImageUrl!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 500,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error, size: 50),
          ),
        );
      },
    );
  }

  Widget _buildCardInfo() {
    if (revealedName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            revealedName!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (revealedSet != null) ...[
            const SizedBox(height: 12),
            Text(
              'Set: $revealedSet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton.icon(
      onPressed: nextCard,
      icon: const Icon(Icons.skip_next),
      label: const Text('Next Card'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF1a237e),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
    );
  }
}
