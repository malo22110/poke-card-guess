import 'package:flutter/material.dart';

class ResultDisplay extends StatelessWidget {
  final bool? isCorrect;
  final String? revealedName;
  final String? revealedSet;
  const ResultDisplay({
    super.key,
    required this.isCorrect,
    required this.revealedName,
    required this.revealedSet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCorrect != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              isCorrect! ? 'Correct!' : 'Nice try!',
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
      ],
    );
  }
}
