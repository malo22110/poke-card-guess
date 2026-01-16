import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:url_launcher/url_launcher.dart';
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
    
    // Register the PayPal button container factory for Flutter Web
    ui_web.platformViewRegistry.registerViewFactory(
      'paypal-button-container',
      (int viewId) => html.DivElement()
        ..id = 'paypal-button-actual-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minHeight = '200px'
        ..style.backgroundColor = 'transparent',
    );
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _loadPayPalScript() {
    // Load PayPal SDK script
    final clientId = AppConfig.paypalClientId;
    final currency = AppConfig.paypalCurrency;
    
    final script = html.ScriptElement()
      ..src = 'https://www.paypal.com/sdk/js?client-id=$clientId&currency=$currency'
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
      
      if (authToken != null) {
        // Record donation on backend (Authenticated users)
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
            // Use trophies returned by the backend if available
            if (data['newTrophies'] != null && (data['newTrophies'] as List).isNotEmpty) {
              TrophyService().showTrophies(data['newTrophies']);
            } else {
               // Fallback to manual check only for authenticated users
              _checkDonationTrophies(data['totalDonated'] / 100);
            }
          }
        } 
        // Note: If backend fails, we still consider the PayPal transaction a success from user POV,
        // but maybe log it? For now, we proceed to show success message.
      }

      if (mounted) {
        // Show success message (Everyone)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for your \$${amount.toStringAsFixed(2)} donation!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() => _isLoading = false);
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
        final data = jsonDecode(response.body);
        if (data is Map && data['newTrophies'] != null) {
          final trophies = data['newTrophies'] as List;
          if (trophies.isNotEmpty) {
            TrophyService().showTrophies(trophies);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking donation trophies: $e');
    }
  }

  void _renderPayPalButton(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.indigo.shade800,
        title: const Text('Complete Your Donation', style: TextStyle(color: Colors.white)),
        content: PayPalButtonWidget(
          amount: amount,
          onSuccess: () async {
            await _processDonation(amount);
            if (mounted) Navigator.of(context).pop();
          },
          onCancel: () {
            if (mounted) Navigator.of(context).pop();
          },
          onError: (err) {
            setState(() => _error = 'Payment failed: $err');
            if (mounted) Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
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
                      _renderPayPalButton(amount);
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

class PayPalButtonWidget extends StatefulWidget {
  final double amount;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final Function(dynamic) onError;

  const PayPalButtonWidget({
    super.key,
    required this.amount,
    required this.onSuccess,
    required this.onCancel,
    required this.onError,
  });

  @override
  State<PayPalButtonWidget> createState() => _PayPalButtonWidgetState();
}

class _PayPalButtonWidgetState extends State<PayPalButtonWidget> {
  bool _rendered = false;

  @override
  void initState() {
    super.initState();
    // Render the button after the frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderPayPal();
    });
  }

  void _renderPayPal() {
    if (_rendered) return;
    
    try {
      final paypal = js.context['paypal'];
      if (paypal == null) {
        widget.onError('PayPal SDK not loaded');
        return;
      }

      final buttons = paypal.callMethod('Buttons', [
        js.JsObject.jsify({
          'createOrder': js.allowInterop((data, actions) {
            final actionsObj = actions as js.JsObject;
            return actionsObj['order'].callMethod('create', [
              js.JsObject.jsify({
                'purchase_units': [
                  {
                    'amount': {
                      'value': widget.amount.toStringAsFixed(2),
                      'currency_code': 'USD'
                    }
                  }
                ]
              })
            ]);
          }),
          'onApprove': js.allowInterop((data, actions) {
            final actionsObj = actions as js.JsObject;
            return actionsObj['order'].callMethod('capture', []).callMethod('then', [
              js.allowInterop((details) {
                widget.onSuccess();
              })
            ]);
          }),
          'onError': js.allowInterop((err) {
            widget.onError(err);
          }),
          'onCancel': js.allowInterop((data) {
            widget.onCancel();
          }),
        })
      ]);

      // Render into the div that was created by the factory
      // We use a small delay to make sure the div is actually in the DOM
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          try {
            buttons.callMethod('render', ['#paypal-button-actual-container']);
            setState(() => _rendered = true);
          } catch (e) {
            debugPrint('PayPal render error: $e');
            // Try again once more if it fails
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_rendered) {
                buttons.callMethod('render', ['#paypal-button-actual-container']);
                setState(() => _rendered = true);
              }
            });
          }
        }
      });
    } catch (e) {
      widget.onError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: const BoxConstraints(minHeight: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Donating \$${widget.amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Wrap in a container with a visible height and optional debug border
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const HtmlElementView(viewType: 'paypal-button-container'),
          ),
          if (!_rendered) 
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
