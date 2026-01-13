import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokeCardGuessApp());
}

class PokemonCard {
  final String id;
  final String name;
  final CardImages images;
  final CardSet? set;
  final List<String>? types;
  final String? supertype;

  PokemonCard({
    required this.id,
    required this.name,
    required this.images,
    this.set,
    this.types,
    this.supertype,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'],
      name: json['name'],
      images: CardImages.fromJson(json['images']),
      set: json['set'] != null ? CardSet.fromJson(json['set']) : null,
      types: json['types'] != null ? List<String>.from(json['types']) : null,
      supertype: json['supertype'],
    );
  }
}

class CardImages {
  final String large;

  CardImages({required this.large});

  factory CardImages.fromJson(Map<String, dynamic> json) {
    return CardImages(large: json['large']);
  }
}

class CardSet {
  final String name;

  CardSet({required this.name});

  factory CardSet.fromJson(Map<String, dynamic> json) {
    return CardSet(name: json['name']);
  }
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
  PokemonCard? currentCard;
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
    loadRandomCard();
  }

  Future<void> loadRandomCard() async {
    setState(() {
      isLoading = true;
      showFullCard = false;
      error = null;
      isCorrect = null;
      _guessController.clear();
    });

    try {
      // Call our backend instead of the external API directly
      final response = await http.get(Uri.parse('http://localhost:3000/game/card'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentCard = PokemonCard.fromJson(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load card: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load card: $e';
        isLoading = false;
      });
    }
  }

  void checkGuess() {
    if (currentCard == null || _guessController.text.isEmpty) return;

    final guess = _guessController.text.trim().toLowerCase();
    final actualName = currentCard!.name.toLowerCase();

    // Check if the guess is contained in the card name (e.g. "Pikachu" in "Surfing Pikachu")
    // We ignore case and require at least 3 characters to avoid false positives with short strings
    if (actualName.contains(guess) && guess.length >= 3) {
      setState(() {
        isCorrect = true;
        showFullCard = true;
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

  void giveUp() {
    setState(() {
      showFullCard = true;
      isCorrect = false;
      attempts++;
    });
  }

  void nextCard() {
    loadRandomCard();
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
          onPressed: loadRandomCard,
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
    if (currentCard == null) {
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
        isCorrect! ? 'Correct! It\'s ${currentCard!.name}!' : 'Nice try! It was ${currentCard!.name}.',
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
    final imageUrl = currentCard!.images.large;
    
    return Hero(
      tag: 'card_${currentCard!.id}',
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
                // Card image with crop effect
                if (!showFullCard)
                  _buildCroppedCard(imageUrl)
                else
                  _buildFullCard(imageUrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCroppedCard(String imageUrl) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Only show bottom 30% of the card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.3, // Show only bottom 30%
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 500,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, size: 50),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Gradient overlay at the top to create mystery effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
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

  Widget _buildFullCard(String imageUrl) {
    return Image.network(
      imageUrl,
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
            currentCard!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (currentCard!.supertype != null)
            Text(
              '${currentCard!.supertype} - ${currentCard!.types?.join(", ") ?? "Unknown"}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          if (currentCard!.set != null) ...[
            const SizedBox(height: 12),
            Text(
              'Set: ${currentCard!.set!.name}',
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
