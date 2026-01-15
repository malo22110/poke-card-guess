import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:pokecardguess/config/app_config.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? authToken;
  final bool isGuest;

  const ProfileSetupScreen({
    super.key, 
    this.authToken, 
    this.isGuest = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final List<String> _avatars = [
    'assets/images/pokeball.png', 
  ];
  String _selectedAvatar = 'default'; 
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer access to context until build or post-frame, but Provider listen=false is safe in initState usually?
    // Actually no, inherited widgets in initState can be tricky.
    // Better to use WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!widget.isGuest && authService.currentUser != null) {
         setState(() {
            _usernameController.text = authService.currentUser!.name;
         });
      }
    });
  }

  Future<void> _submitProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Username is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      if (widget.isGuest) {
        await authService.loginAsGuest(username, _selectedAvatar);
        
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/lobby');
        }
      } else {
        final response = await http.patch(
          Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.authToken}',
          },
          body: jsonEncode({
            'name': username,
            'picture': _selectedAvatar,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
           await authService.login(widget.authToken!); 
           
           if (mounted) {
             Navigator.of(context).pushReplacementNamed('/lobby');
           }
        } else {
          throw Exception('Failed to update profile: ${response.body}');
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2937),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Setup Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Avatar Selection (Simplified for now)
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Avatar (Coming Soon)',
                  style: TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 32),
                
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),

                const SizedBox(height: 32),
                
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
