import 'package:flutter/material.dart';
import 'package:pokecardguess/models/trophy.dart';

class TrophyCard extends StatelessWidget {
  final Trophy trophy;
  final bool isUnlocked;
  final int? progress;
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [
                  Colors.grey.shade800,
                  Colors.grey.shade900,
                ]
              : [
                  tierColor.withOpacity(0.2),
                  tierColor.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? Colors.grey.shade700 : tierColor,
          width: 2,
        ),
        boxShadow: isLocked
            ? []
            : [
                BoxShadow(
                  color: tierColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and tier badge
            Row(
              children: [
                // Trophy Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade800
                        : tierColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLocked ? Colors.grey.shade600 : tierColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      trophy.icon,
                      style: TextStyle(
                        fontSize: 32,
                        color: isLocked ? Colors.grey.shade600 : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trophy Name
                      Text(
                        trophy.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey.shade500 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Tier Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.grey.shade700
                              : tierColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLocked ? Colors.grey.shade600 : tierColor,
                          ),
                        ),
                        child: Text(
                          _getTierLabel(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey.shade500 : tierColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock/Check Icon
                Icon(
                  isLocked ? Icons.lock : Icons.check_circle,
                  color: isLocked ? Colors.grey.shade600 : tierColor,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              trophy.description,
              style: TextStyle(
                fontSize: 14,
                color: isLocked ? Colors.grey.shade600 : Colors.grey.shade300,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Progress Bar (if locked and has progress)
            if (isLocked && progress != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progress / ${trophy.requirement}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress! / trophy.requirement,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
            // Unlocked Date
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unlocked ${_formatDate(unlockedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
