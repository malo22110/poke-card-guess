import 'package:flutter/material.dart';

class GuessInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onGuessSubmitted;
  final VoidCallback onGiveUp;

  const GuessInput({
    super.key,
    required this.controller,
    required this.onGuessSubmitted,
    required this.onGiveUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: controller,
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
                onPressed: onGuessSubmitted,
              ),
            ),
            onSubmitted: (_) => onGuessSubmitted(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onGuessSubmitted,
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
              onPressed: onGiveUp,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Give Up'),
            ),
          ],
        ),
      ],
    );
  }
}
