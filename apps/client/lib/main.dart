import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/game_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/create_game_screen.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/auth_callback_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/trophies_screen.dart';
import 'screens/leaderboard_screen.dart';

import 'services/auth_service.dart';
import 'services/sound_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SoundService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
          );
        }

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
            // Create a new mutable map to properly handle type mixing (e.g., bool from code, string from URI)
            final args = <String, dynamic>{};
            
            if (settings.arguments != null) {
              // We must manually copy entries if casting is unsafe, or strict map creation
              // Map.from works well to convert valid source maps
              final passedArgs = settings.arguments as Map;
              passedArgs.forEach((key, value) {
                if (key is String) args[key] = value;
              });
            }
            args.addAll(uri.queryParameters);

            // Reconstruct primitives
            // Removed manual boolean conversion to avoid TypeErrors
            // checking 'true' strings should be done in the destination screens

            // Route Guard Logic
            // If user is NOT logged in (neither guest nor auth), restricted to Login or public pages if any
            // Actually, if not logged in, we redirect to Login for almost everything except maybe Terms?
            final publicRoutes = ['/login', '/terms', '/auth_callback', '/profile-setup'];
            
            if (authService.currentUser == null && !publicRoutes.contains(uri.path)) {
               return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: const RouteSettings(name: '/login'));
            }

            // If user IS logged in, prevent access to Login
            if (uri.path == '/login' && authService.currentUser != null) {
              return MaterialPageRoute(
                builder: (_) => LobbyScreen(authToken: authService.currentUser?.authToken),
                settings: const RouteSettings(name: '/lobby')
              );
            }

            final newSettings = RouteSettings(name: settings.name, arguments: args);
            final authToken = authService.currentUser?.authToken;

            switch (uri.path) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: newSettings);
              case '/game':
                return MaterialPageRoute(builder: (_) => const GameScreen(), settings: newSettings);
              case '/lobby':
                return MaterialPageRoute(builder: (_) => LobbyScreen(authToken: authToken), settings: newSettings);
              case '/create-game':
                return MaterialPageRoute(builder: (_) => const CreateGameScreen(), settings: newSettings);
              case '/waiting-room':
                return MaterialPageRoute(builder: (_) => const WaitingRoomScreen(), settings: newSettings);
              case '/auth_callback':
                return MaterialPageRoute(
                  builder: (_) => AuthCallbackScreen(token: args['token'] ?? ''), 
                  settings: newSettings
                );
              case '/profile':
                return MaterialPageRoute(builder: (_) => ProfileScreen(authToken: authToken), settings: newSettings);
              case '/profile-setup':
                 return MaterialPageRoute(
                  builder: (_) => ProfileSetupScreen(
                    authToken: authToken,
                    isGuest: args['isGuest'] == true,
                  ), 
                  settings: newSettings
                );
              case '/terms':
                return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen(), settings: newSettings);
              case '/trophies':
                return MaterialPageRoute(builder: (_) => TrophiesScreen(authToken: authToken), settings: newSettings);
              case '/leaderboard':
                return MaterialPageRoute(builder: (_) => LeaderboardScreen(authToken: authToken), settings: newSettings);
            }
            return null;
          },
          home: authService.currentUser != null 
              ? LobbyScreen(authToken: authService.currentUser?.authToken) 
              : const LoginScreen(),
        );
      },
    );
  }
}
