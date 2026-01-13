import 'package:flutter/material.dart';

class ResultDisplay extends StatelessWidget {
  final bool? isCorrect;
  final String? revealedName;
  final String? revealedSet;
  final VoidCallback onNextCard;
  final bool showNextButton;

  const ResultDisplay({
    super.key,
    required this.isCorrect,
    required this.revealedName,
    required this.revealedSet,
    required this.onNextCard,
    this.showNextButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCorrect != null)
          Padding(
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
          ),
        if (revealedName != null)
          Container(
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
          ),
        const SizedBox(height: 16),
        if (showNextButton)
          ElevatedButton.icon(
            onPressed: onNextCard,
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
          ),
      ],
    );
  }
}
