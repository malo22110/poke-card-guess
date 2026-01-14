import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/create_game_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/auth_callback_screen.dart';

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
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        
        // Merge arguments from URL query params and internal navigation args
        final initialArgs = (settings.arguments as Map<String, dynamic>?) ?? <String, dynamic>{};
        final args = Map<String, dynamic>.from(initialArgs);
        args.addAll(uri.queryParameters);
        
        // Type conversion for boolean flags from URL
        if (args['isHost'] == 'true') args['isHost'] = true;
        if (args['isHost'] == 'false') args['isHost'] = false;

        final newSettings = RouteSettings(name: settings.name, arguments: args);

        switch (uri.path) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: newSettings);
          case '/game':
            return MaterialPageRoute(builder: (_) => const GameScreen(), settings: newSettings);
          case '/lobby':
            return MaterialPageRoute(builder: (_) => LobbyScreen(authToken: args['authToken']), settings: newSettings);
          case '/create-game':
            return MaterialPageRoute(builder: (_) => const CreateGameScreen(), settings: newSettings);
          case '/waiting-room':
            return MaterialPageRoute(builder: (_) => const WaitingRoomScreen(), settings: newSettings);
          case '/auth_callback':
            return MaterialPageRoute(
              builder: (_) => AuthCallbackScreen(token: args['token'] ?? ''), 
              settings: newSettings
            );
        }
        return null;
      },
      home: _authToken != null ? LobbyScreen(authToken: _authToken) : const LoginScreen(),
    );
  }
}
