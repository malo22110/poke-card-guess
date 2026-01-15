import 'package:flutter/material.dart';
import '../../services/sound_service.dart';

class GameHeader extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final int? remainingSeconds;
  final int currentStreak;

  const GameHeader({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    this.remainingSeconds,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Guess the Pokemon!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (remainingSeconds != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _getTimerColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getTimerColor(), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: _getTimerColor(), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${remainingSeconds}s',
                    style: TextStyle(
                      color: _getTimerColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Streak Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentStreak >= 3
                    ? [Colors.orange.shade700, Colors.red.shade700]
                    : [Colors.purple.shade700, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentStreak >= 3 ? Colors.orange : Colors.purple.shade300,
                width: 2,
              ),
              boxShadow: currentStreak >= 3
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  currentStreak >= 3 ? Icons.local_fire_department : Icons.whatshot,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: SoundService(),
            builder: (context, _) {
              return GestureDetector(
                onTap: () => SoundService().toggleMute(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(
                    SoundService().isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
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
                const Icon(Icons.style, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Round: $currentRound / $totalRounds',
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

  Color _getTimerColor() {
    if (remainingSeconds == null) return Colors.white;
    if (remainingSeconds! > 20) return Colors.green;
    if (remainingSeconds! > 10) return Colors.orange;
    return Colors.red;
  }
}
