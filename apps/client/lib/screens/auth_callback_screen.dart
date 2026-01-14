import 'package:flutter/material.dart';

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
    // Schedule navigation to the request frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToLobby();
    });
  }

  void _navigateToLobby() {
    print('AuthCallback received token, redirecting to lobby...');
    // Navigate to lobby and replace the current route so the user can't go back to the callback URL
    Navigator.of(context).pushReplacementNamed(
      '/lobby',
      arguments: {'authToken': widget.token},
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
