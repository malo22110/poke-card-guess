import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationScreen extends StatelessWidget {
  final String? authToken;
  
  const DonationScreen({super.key, this.authToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        title: const Text('Support PokeCardGuess'),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade700, Colors.indigo.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Support PokeCardGuess',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help keep the game alive and unlock exclusive trophies!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Donation Trophies
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Donation Trophies',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTrophyItem('💝 Supporter', 'First donation', Colors.brown),
                      _buildTrophyItem('💝 Generous', '\$5 or more', Colors.grey),
                      _buildTrophyItem('💝 Patron', '\$20 or more', Colors.amber),
                      _buildTrophyItem('💝 Benefactor', '\$50 or more', Colors.cyan),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Donate Button
                ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=3W3L9NC2BVGSS');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Donate with PayPal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Secure payment powered by PayPal\nContact us after donating to unlock your trophies!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrophyItem(String name, String requirement, Color tierColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 8),
          Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          const SizedBox(width: 8),
          Text(requirement, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }
}
