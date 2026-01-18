import 'package:flutter/material.dart';
import 'package:pokecardguess/config/app_config.dart';

class StoryShareCard extends StatelessWidget {
  final int score;
  final List<Map<String, dynamic>> cardHistory;
  final String userName;
  final String? userPicture;

  const StoryShareCard({
    super.key,
    required this.score,
    required this.cardHistory,
    required this.userName,
    this.userPicture,
  });

  @override
  Widget build(BuildContext context) {
    // 9:16 Aspect Ratio Layout
    // We will render this in a fixed size context usually, e.g., 1080x1920 scaled down
    return Container(
      width: 360, // Logic width
      height: 640, // Logic height (9:16)
      decoration: BoxDecoration(
        color: Colors.indigo.shade900, // Fallback color
        image: DecorationImage(
          image: const AssetImage('assets/images/landscape.webp'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6), 
            BlendMode.darken
          ),
          onError: (exception, stackTrace) {
              // Error logging or handling if needed
              debugPrint('Error loading background: $exception');
          }
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header / Logo
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Image.asset(
              'assets/images/pokecardguess.webp',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'PokeCardGuess',
                style: TextStyle(
                  color: Colors.indigo,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 5),
          
          // User / Score
          if (userPicture != null)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(userPicture!),
              backgroundColor: Colors.white,
            ),
          const SizedBox(height: 4),
          Text(
            'I just scored',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 80,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: [
                Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
          ),
          const Text(
            'POINTS',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          
          const Spacer(),
          
          // Cards Showcase (Top cards by points earned)
          if (cardHistory.isNotEmpty) ...[
             const Text('My best guesses', style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
             const SizedBox(height: 10),
             Wrap(
               spacing: 10,
               runSpacing: 10,
               alignment: WrapAlignment.center,
               children: (cardHistory.toList()
                 ..sort((a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0)))
                 .take(4)
                 .map((card) {
                 return Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(6),
                     boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(6),
                     child: Image.network(
                       card['imageUrl'] ?? '',
                       width: 60,
                       height: 84,
                       fit: BoxFit.cover,
                       errorBuilder: (c,e,s) => Container(width:60, height:84, color:Colors.white24),
                     ),
                   ),
                 );
               }).toList(),
             ),
          ],
          
          const Spacer(),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade700.withOpacity(0.9),
                  Colors.indigo.shade800.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Can you beat me?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Play now at',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Text(
                    'pokecardguess.com',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
