import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokecardguess/config/app_config.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? authToken;

  const LeaderboardScreen({super.key, this.authToken});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _gameModes = [];
  List<dynamic> _leaderboard = [];
  String? _selectedGameModeId;
  bool _isLoadingModes = true;
  bool _isLoadingLeaderboard = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGameModes();
  }

  Future<void> _fetchGameModes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes'),
        // Auth not strictly required for reading modes, but good practice
        headers: widget.authToken != null 
          ? {'Authorization': 'Bearer ${widget.authToken}'}
          : {},
      );

      if (response.statusCode == 200) {
        final modes = jsonDecode(response.body);
        setState(() {
          _gameModes = modes;
          _isLoadingModes = false;
          if (modes.isNotEmpty) {
            _selectedGameModeId = modes[0]['id'];
            _fetchLeaderboard(_selectedGameModeId!);
          }
        });
      } else {
        throw Exception('Failed to load game modes');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading modes: $e';
        _isLoadingModes = false;
      });
    }
  }

  Future<void> _fetchLeaderboard(String gameModeId) async {
    setState(() {
      _isLoadingLeaderboard = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes/$gameModeId/leaderboard'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _leaderboard = jsonDecode(response.body);
          _isLoadingLeaderboard = false;
        });
      } else {
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading leaderboard: $e';
        _isLoadingLeaderboard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            if (_isLoadingModes)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              _buildModeSelector(),
            
            Expanded(
              child: _isLoadingLeaderboard 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _buildLeaderboardList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    if (_gameModes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No game modes found', style: TextStyle(color: Colors.white)),
      );
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _gameModes.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mode = _gameModes[index];
          final isSelected = mode['id'] == _selectedGameModeId;
          
          return ActionChip(
            label: Text(mode['name']),
            onPressed: () {
              setState(() => _selectedGameModeId = mode['id']);
              _fetchLeaderboard(mode['id']);
            },
            backgroundColor: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            avatar: mode['isOfficial'] == true 
                ? const Icon(Icons.verified, size: 16, color: Colors.blue) 
                : null,
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardList() {
    if (_leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No scores yet for this mode',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final entry = _leaderboard[index];
        final rank = index + 1;
        final user = entry['user'];
        // Default avatar if none provided (assuming user['picture'] might be a URL or null)
        // Also handling null user gracefully
        final userName = user?['name'] ?? 'Unknown Player';
        final userPic = user?['picture'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index < 3 ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: index == 0 ? Colors.amber : Colors.transparent,
              width: index == 0 ? 2 : 0,
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 40,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: index < 3 ? Colors.amber : Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                backgroundImage: userPic != null ? NetworkImage(userPic) : null,
                child: userPic == null 
                  ? Text(userName[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                  : null,
              ),
              
              const SizedBox(width: 16),
              
              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${entry['rounds']} rounds', // Maybe format date too?
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry['score']} pts',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entry['maxScore'] != null)
                    Text(
                      'of ${entry['maxScore']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
