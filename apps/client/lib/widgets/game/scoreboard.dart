import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokecardguess/config/app_config.dart';

class Scoreboard extends StatelessWidget {
  final Map<String, int> scores;
  final String? currentUserId;
  final Map<String, String>? playerStatuses;
  final Map<String, String>? playerNames;
  final Map<String, String?>? playerPictures; // userId -> picture URL
  final VoidCallback? onShare;

  const Scoreboard({
    super.key,
    required this.scores,
    this.currentUserId,
    this.playerStatuses,
    this.playerNames,
    this.playerPictures,
    this.onShare,
  });

  String? _resolveAvatarUrl(String? pic) {
    if (pic == null) return null;
    if (pic.startsWith('http')) return pic;
    return '${AppConfig.apiBaseUrl}$pic';
  }

  @override
  Widget build(BuildContext context) {
    // Sort players by score (descending)
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Scoreboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final playerEntry = entry.value;
            final playerId = playerEntry.key;
            final score = playerEntry.value;
            final isCurrentUser = playerId == currentUserId;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentUser 
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Avatar (with rank overlay)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      () {
                        final pic = _resolveAvatarUrl(playerPictures?[playerId]);
                        final initial = (playerNames?[playerId] ?? playerId).substring(0, 1).toUpperCase();
                        return CircleAvatar(
                          radius: 16,
                          backgroundColor: _getRankColor(index),
                          backgroundImage: pic != null
                              ? CachedNetworkImageProvider(pic)
                              : null,
                          child: pic == null
                              ? Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                              : null,
                        );
                      }(),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Player Details (Two Rows)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          playerNames?[playerId] ?? playerId,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Score & Status
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$score pts',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isCurrentUser && onShare != null) ...[
                               const SizedBox(width: 8),
                               InkWell(
                                 onTap: onShare,
                                 child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.share, size: 12, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Share', 
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ],
                                  ),
                                 ),
                               ),
                            ],
                            const Spacer(),
                            _buildStatusIcon(playerStatuses?[playerId]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[400]!; // Silver
      case 2:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildStatusIcon(String? status) {
    if (status == 'guessed') {
      return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24);
    } else if (status == 'given_up') {
      return const Icon(Icons.cancel, color: Colors.redAccent, size: 24);
    }
    return const SizedBox(width: 24);
  }
}
