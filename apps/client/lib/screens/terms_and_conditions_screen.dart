import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFF1F2937),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal Disclaimer & Terms of Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('1. Disclaimer regarding Intellectual Property'),
              _buildParagraph(
                'PokeCardGuess is an unofficial, free fan-made game. This project is NOT affiliated with, endorsed, sponsored, or specifically approved by Nintendo, Game Freak, or The Pokémon Company.\n\n'
                'Pokémon and Pokémon character names are trademarks of Nintendo. All related images and data (including card images) are the property of their respective owners. This project uses these assets under the principle of Fair Use for educational and entertainment purposes only.'
              ),
              _buildSectionTitle('2. Non-Commercial Use'),
              _buildParagraph(
                'This application is entirely non-commercial. No money is charged for playing, and there are no in-app purchases or advertisements. It is an open-source educational project demonstrating web and mobile development technologies.'
              ),
               _buildSectionTitle('3. Privacy Policy'),
              _buildParagraph(
                 'We value your privacy. When you log in with Google or Facebook, we only store your email, name, and profile picture to create your user profile. We do not sell or share your data with any third parties.'
              ),
               _buildSectionTitle('4. User Conduct'),
              _buildParagraph(
                 'By playing this game, you agree to play fairly and respect other players. Cheating, hacking, or using exploits to manipulate game scores is prohibited.'
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Last Updated: January 2026',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }
}
