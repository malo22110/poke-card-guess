import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_storage_service.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String token;

  const AuthCallbackScreen({super.key, required this.token});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileAndNavigate();
    });
  }

  bool _isChecking = true;
  String? _errorMessage;

  Future<void> _checkProfileAndNavigate() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );


      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        
        // Save session securely
        await AuthStorageService().saveSession(
          token: widget.token,
          userId: user['id']?.toString(),
          userName: user['name']?.toString(),
        );

        final profileCompleted = user['profileCompleted'] == true;

        if (!mounted) return;

        if (profileCompleted) {
          Navigator.of(context).pushReplacementNamed(
            '/lobby',
            arguments: {'authToken': widget.token},
          );
        } else {
           Navigator.of(context).pushReplacementNamed(
            '/profile-setup',
            arguments: {'authToken': widget.token},
          );
        }
      } else {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Failed to load profile (Status ${response.statusCode})';
        });
      }
    } catch (e) {
      print('Error checking profile: $e');
      setState(() {
        _isChecking = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: Center(
        child: _errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                   const SizedBox(height: 16),
                   Text(
                     'Oops!',
                     style: TextStyle(
                       color: Colors.white.withOpacity(0.9),
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 32),
                     child: Text(
                       _errorMessage!,
                       textAlign: TextAlign.center,
                       style: const TextStyle(color: Colors.white70),
                     ),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: _checkProfileAndNavigate,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.amber, 
                       foregroundColor: Colors.black,
                     ),
                     child: const Text('Retry'),
                   ),
                   const SizedBox(height: 16),
                   TextButton(
                     onPressed: () {
                       // Allow user to try to go to lobby anyway if they insist
                       Navigator.of(context).pushReplacementNamed(
                          '/lobby',
                          arguments: {'authToken': widget.token},
                       );
                     },
                     child: const Text('Go to Lobby (Skip Check)', style: TextStyle(color: Colors.white54)),
                   )
                ],
              )
            : const CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}
