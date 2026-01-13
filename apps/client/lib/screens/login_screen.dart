import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginGoogle() async {
    final url = Uri.parse('http://localhost:3000/auth/google');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_self');
    }
  }

  Future<void> _loginFacebook() async {
    final url = Uri.parse('http://localhost:3000/auth/facebook');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_self');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF3B4CCA),
              Color(0xFF5E35B1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.catching_pokemon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PokeCard Guess',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to save your progress!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Login Buttons
                  _buildLoginButton(
                    onPressed: _loginGoogle,
                    icon: Icons.g_mobiledata, // Using a generic icon for now, ideally use a Google asset
                    label: 'Sign in with Google',
                    color: Colors.white,
                    textColor: Colors.black87,
                  ),
                  const SizedBox(height: 16),
                  _buildLoginButton(
                    onPressed: _loginFacebook,
                    icon: Icons.facebook,
                    label: 'Sign in with Facebook',
                    color: const Color(0xFF1877F2),
                    textColor: Colors.white,
                  ),
                  
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      // Navigate to LobbyScreen directly (Guest mode)
                      Navigator.of(context).pushReplacementNamed('/lobby');
                    },
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
