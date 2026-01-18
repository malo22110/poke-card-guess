import 'package:flutter/material.dart';

class ResultDisplay extends StatelessWidget {
  final bool? isCorrect;
  final String? revealedName;
  final String? revealedSet;
  final int? score;
  final String? userGuess;

  const ResultDisplay({
    super.key,
    required this.isCorrect,
    required this.revealedName,
    required this.revealedSet,
    this.score,
    this.userGuess,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isCorrect != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isCorrect! 
                  ? (score != null ? '+$score pts' : 'Correct!') 
                  : 'Time\'s up!',
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
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              revealedName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
        if (revealedSet != null && revealedSet!.isNotEmpty)
          Padding(
             padding: const EdgeInsets.only(bottom: 12),
             child: Text(
               revealedSet!,
               style: TextStyle(
                 color: Colors.white.withOpacity(0.7),
                 fontSize: 14,
                 fontStyle: FontStyle.italic,
               ),
               textAlign: TextAlign.center,
             )
          ),

        if (userGuess != null && userGuess!.isNotEmpty && userGuess!.toLowerCase() != revealedName?.toLowerCase())
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Text('You guessed: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                 Text(
                   userGuess!, 
                   style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                 ),
               ],
             ),
          ),
      ],
    );
  }
}
