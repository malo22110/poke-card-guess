import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    'assets/images/pokeball.png', // We might need to ensure these exist or use placeholders
    // For now let's just use simple colors or indices if we don't have assets
  ];
  String _selectedAvatar = 'default'; // Placeholder
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest && widget.authToken != null) {
      _fetchCurrentProfile();
    }
  }

  Future<void> _fetchCurrentProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['name'] != null && mounted) {
          setState(() {
            _usernameController.text = data['name'];
          });
        }
        // Could also pre-fill avatar if we supported URL avatars
      }
    } catch (e) {
      print('Failed to fetch current profile: $e');
    }
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

    try {
      if (widget.isGuest) {
        // For guest, we just pass the info forward to the lobby
        // We'll simulate a "token" or just pass args. 
        // Actually, lobby expects authToken. If guest, we usually just go to lobby.
        // We need to pass guestName to lobby.
        Navigator.of(context).pushReplacementNamed('/lobby', arguments: {
          'guestName': username,
          'guestAvatar': _selectedAvatar,
          // No auth token
        });
      } else {
        // Authenticated user: Update backend
        final response = await http.patch(
          Uri.parse('http://localhost:3000/users/profile'),
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
           Navigator.of(context).pushReplacementNamed('/lobby', arguments: {
             'authToken': widget.authToken
           });
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
