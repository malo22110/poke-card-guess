import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('token')) {
      setState(() {
        _authToken = uri.queryParameters['token'];
      });
      print('Logged in with token: $_authToken');
      // In a real app, you'd verify this token and/or store it in shared_preferences
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeCardGuess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/game': (context) => const GameScreen(),
      },
      // If we have a token, start at GameScreen, otherwise LoginScreen
      home: _authToken != null ? const GameScreen() : const LoginScreen(),
    );
  }
}
