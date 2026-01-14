import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GameFooter extends StatelessWidget {
  const GameFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

           InkWell(
            onTap: () {
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   backgroundColor: const Color(0xFF1F2937),
                   title: const Text('Support PokeCardGuess', style: TextStyle(color: Colors.white)),
                   content: const Text(
                     'PokeCardGuess is a free fan project.\n\n'
                     'Your donation helps cover server hosting costs and supports the development of new features and game modes.\n\n'
                     'Every bit helps keep the game alive!',
                     style: TextStyle(color: Colors.white70),
                   ),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(context),
                       child: const Text('Cancel'),
                     ),
                     ElevatedButton.icon(
                       onPressed: () {
                         Navigator.pop(context);
                         launchUrl(Uri.parse('https://www.paypal.com/donate/?hosted_button_id=3W3L9NC2BVGSS')); 
                       },
                       icon: const Icon(Icons.favorite, size: 18),
                       label: const Text('Donate'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF003087),
                         foregroundColor: Colors.white,
                       ),
                     ),
                   ],
                 ),
               );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF003087), // PayPal Blue
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF009cde), width: 1), // PayPal Light Blue
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Donate & Support',
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            'PokeCardGuess is an unofficial fan game and is not affiliated with Nintendo, Game Freak, or The Pokémon Company.\nAll assets belong to their respective owners.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© 2026 PokeCardGuess',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/terms');
                },
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
