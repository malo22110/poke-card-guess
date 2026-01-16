import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/footer.dart';
import 'package:pokecardguess/config/app_config.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginGoogle() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/google');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: '_self');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/landscape.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                     minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Title area
                  Image.asset(
                    'assets/images/pokecardguess.png',
                    height: 300,
                    fit: BoxFit.contain,
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

                  
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () {
                      // Navigate to ProfileSetupScreen to set guest name
                      Navigator.of(context).pushNamed(
                        '/profile-setup',
                        arguments: {'isGuest': true},
                      );
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
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const GameFooter(),
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
