import 'package:flutter/material.dart';
import 'package:pokecardguess/models/trophy.dart';

class TrophyCard extends StatelessWidget {
  final Trophy trophy;
  final bool isUnlocked;
  final num? progress;
  final DateTime? unlockedAt;

  const TrophyCard({
    super.key,
    required this.trophy,
    this.isUnlocked = false,
    this.progress,
    this.unlockedAt,
  });

  Color _getTierColor() {
    switch (trophy.tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'special':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  String _getTierLabel() {
    return trophy.tier.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor();
    final isLocked = !isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFF1E1E1E) : tierColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLocked ? Colors.white10 : tierColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // 1. Tiny Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLocked ? Colors.white.withOpacity(0.05) : tierColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                trophy.icon,
                style: TextStyle(
                  fontSize: 16,
                  color: isLocked ? Colors.grey.shade600 : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        trophy.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? Colors.grey.shade400 : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Micro Tier Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: tierColor.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        _getTierLabel(),
                        style: TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  trophy.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // 3. Compact Trailing Status
          if (isLocked && progress != null) ...[
            if (trophy.category == 'speed' || 
                ['speed_demon', 'lightning_fast'].contains(trophy.key))
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    progress! >= 999 ? 'Not yet started' : '${progress}s',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Goal: <${trophy.requirement}s',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$progress/${trophy.requirement}',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 32,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        value: (progress! / trophy.requirement).clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            tierColor.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
              )
          ] else if (isUnlocked && unlockedAt != null) ...[
            Text(
              _formatDate(unlockedAt!),
              style: TextStyle(
                fontSize: 9,
                color: tierColor.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
             Icon(
              isLocked ? Icons.lock_outline : Icons.check_circle_outline,
              size: 14,
              color: isLocked ? Colors.grey.shade800 : tierColor.withOpacity(0.6),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
