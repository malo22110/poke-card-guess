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

  TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              child: _searchText.isNotEmpty 
                  ? _buildSearchResults()
                  : (_isLoadingLeaderboard 
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _buildLeaderboardList()),
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

    // Top 10 (or first 10) modes
    final topModes = _gameModes.take(10).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Horizontal List of Top 10
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: topModes.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = topModes[index];
              final isSelected = mode['id'] == _selectedGameModeId;
              
              return ActionChip(
                label: Text(mode['name']),
                onPressed: () {
                  setState(() {
                    _selectedGameModeId = mode['id'];
                    _searchText = ''; // Clear search when picking from top list
                    _searchController.clear();
                  });
                  _fetchLeaderboard(mode['id']);
                },
                backgroundColor: isSelected ? Colors.amber : Colors.white.withOpacity(0.9),
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: mode['isOfficial'] == true 
                    ? const Icon(Icons.verified, size: 16, color: Colors.blue) 
                    : null,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        ),

        // 2. Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search other game modes...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchText.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchText = '';
                      });
                    },
                  ) 
                : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {
                _searchText = val;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final results = _gameModes.where((mode) {
      final name = mode['name'].toString().toLowerCase();
      final query = _searchText.toLowerCase();
      return name.contains(query);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text('No game modes found matching "$_searchText"', 
          style: TextStyle(color: Colors.white.withOpacity(0.7))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final mode = results[index];
        final isSelected = mode['id'] == _selectedGameModeId;

        return Card(
          color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: mode['isOfficial'] == true 
                ? const Icon(Icons.verified, color: Colors.blue) 
                : const Icon(Icons.videogame_asset, color: Colors.white70),
            title: Text(mode['name'], 
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.amber) : null,
            onTap: () {
              setState(() {
                _selectedGameModeId = mode['id'];
                _searchText = '';
                _searchController.clear();
              });
               FocusScope.of(context).unfocus(); // Dismiss keyboard
              _fetchLeaderboard(mode['id']);
            },
          ),
        );
      },
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
