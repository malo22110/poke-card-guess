import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../config/app_config.dart';
import '../services/auth_storage_service.dart';
import '../services/trophy_service.dart';

class DonationScreen extends StatefulWidget {
  final String? authToken;
  
  const DonationScreen({super.key, this.authToken});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  bool _isLoading = false;
  String? _error;
  
  // Predefined donation amounts
  final List<int> _donationAmounts = [1, 5, 10, 20, 50];
  int? _selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayPalScript();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _loadPayPalScript() {
    // Load PayPal SDK script
    final script = html.ScriptElement()
      ..src = 'https://www.paypal.com/sdk/js?client-id=YOUR_CLIENT_ID&currency=USD'
      ..async = true;
    html.document.head?.append(script);
  }

  Future<void> _processDonation(double amount) async {
    if (amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authStorage = AuthStorageService();
      final authToken = await authStorage.getToken();
      
      if (authToken == null) {
        setState(() {
          _error = 'Please log in to donate';
          _isLoading = false;
        });
        return;
      }

      // Record donation on backend
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/users/donation'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thank you for your \$${amount.toStringAsFixed(2)} donation!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Check for trophies (backend should return them)
          // For now, manually check donation trophies
          _checkDonationTrophies(data['totalDonated'] / 100);
          
          setState(() => _isLoading = false);
        }
      } else {
        setState(() {
          _error = 'Failed to record donation';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkDonationTrophies(double totalDonated) async {
    try {
      final authStorage = AuthStorageService();
      final authToken = await authStorage.getToken();
      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/trophies/check'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'category': 'donation'}),
      );

      if (response.statusCode == 200) {
        final trophies = jsonDecode(response.body) as List;
        if (trophies.isNotEmpty) {
          TrophyService().showTrophies(trophies);
        }
      }
    } catch (e) {
      debugPrint('Error checking donation trophies: $e');
    }
  }

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
                
                // Why Donate Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why Donate?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBulletPoint('Cover server hosting costs'),
                      _buildBulletPoint('Support new features and game modes'),
                      _buildBulletPoint('Keep the game free for everyone'),
                      _buildBulletPoint('Unlock exclusive donation trophies'),
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
                      _buildTrophyItem('💝 Supporter', 'First donation', 'Bronze'),
                      _buildTrophyItem('💝 Generous', '\$5 or more', 'Silver'),
                      _buildTrophyItem('💝 Patron', '\$20 or more', 'Gold'),
                      _buildTrophyItem('💝 Benefactor', '\$50 or more', 'Diamond'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Donation Amount Selection
                const Text(
                  'Select Amount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _donationAmounts.map((amount) {
                    final isSelected = _selectedAmount == amount;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAmount = amount;
                          _customAmountController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.purple.shade600 : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.purple.shade400 : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '\$$amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Custom Amount
                TextField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Custom Amount (\$)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() => _selectedAmount = null);
                    }
                  },
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Donate Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    double amount = 0;
                    if (_customAmountController.text.isNotEmpty) {
                      amount = double.tryParse(_customAmountController.text) ?? 0;
                    } else if (_selectedAmount != null) {
                      amount = _selectedAmount!.toDouble();
                    }
                    
                    if (amount > 0) {
                      // TODO: Integrate PayPal SDK here
                      // For now, show a message
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.indigo.shade800,
                          title: const Text('PayPal Integration', style: TextStyle(color: Colors.white)),
                          content: Text(
                            'PayPal SDK integration is in progress.\n\nYou would donate: \$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      setState(() => _error = 'Please select or enter an amount');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087), // PayPal Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Donate with PayPal',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Secure payment powered by PayPal',
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(String name, String requirement, String tier) {
    Color tierColor;
    switch (tier) {
      case 'Bronze':
        tierColor = Colors.brown;
        break;
      case 'Silver':
        tierColor = Colors.grey;
        break;
      case 'Gold':
        tierColor = Colors.amber;
        break;
      case 'Diamond':
        tierColor = Colors.cyan;
        break;
      default:
        tierColor = Colors.white;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 8),
          Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          const SizedBox(width: 8),
          Text(requirement, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tierColor),
            ),
            child: Text(
              tier,
              style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
