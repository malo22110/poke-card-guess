import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pokecardguess/config/app_config.dart';
import 'package:pokecardguess/models/trophy.dart';
import 'package:pokecardguess/widgets/trophy/trophy_card.dart';
import 'package:pokecardguess/widgets/footer.dart';

class TrophiesScreen extends StatefulWidget {
  final String? authToken;
  
  const TrophiesScreen({super.key, this.authToken});

  @override
  State<TrophiesScreen> createState() => _TrophiesScreenState();
}

class _TrophiesScreenState extends State<TrophiesScreen> {
  List<UserTrophy> _unlockedTrophies = [];
  List<Trophy> _lockedTrophies = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, unlocked, locked
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'score',
    'games',
    'wins',
    'streak',
    'cards',
    'special',
    'leaderboard',
    'personal_best',
    'rarity',
    'set',
    'speed',
    'donation',
    'event',
    'creator',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrophies();
  }

  Future<void> _loadTrophies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/trophies/me'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.authToken != null)
            'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        setState(() {
          _unlockedTrophies = (data['unlocked'] as List)
              .map((t) => UserTrophy.fromJson(t as Map<String, dynamic>))
              .toList();
          _lockedTrophies = (data['locked'] as List)
              .map((t) => Trophy.fromJson(t as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load trophies';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredTrophies() {
    List<dynamic> trophies = [];

    if (_selectedFilter == 'all' || _selectedFilter == 'unlocked') {
      trophies.addAll(_unlockedTrophies);
    }
    if (_selectedFilter == 'all' || _selectedFilter == 'locked') {
      trophies.addAll(_lockedTrophies);
    }

    if (_selectedCategory != 'all') {
      trophies = trophies.where((t) {
        final trophy = t is UserTrophy ? t.trophy : t as Trophy;
        return trophy.category == _selectedCategory;
      }).toList();
    }

    return trophies;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrophies = _getFilteredTrophies();

    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        title: const Text(
          'Trophies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade800,
                  Colors.indigo.shade900,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Unlocked',
                      '${_unlockedTrophies.length}',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'Locked',
                      '${_lockedTrophies.length}',
                      Icons.lock,
                      Colors.grey,
                    ),
                    _buildStatCard(
                      'Total',
                      '${_unlockedTrophies.length + _lockedTrophies.length}',
                      Icons.stars,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${((_unlockedTrophies.length + _lockedTrophies.length) == 0 ? 0 : (_unlockedTrophies.length / (_unlockedTrophies.length + _lockedTrophies.length) * 100)).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_unlockedTrophies.length + _lockedTrophies.length) == 0
                            ? 0.0
                            : _unlockedTrophies.length /
                                (_unlockedTrophies.length + _lockedTrophies.length),
                        backgroundColor: Colors.indigo.shade700,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.indigo.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Unlocked', 'unlocked'),
                      _buildFilterChip('Locked', 'locked'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            category == 'all' ? 'All Categories' : category.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = category);
                            }
                          },
                          selectedColor: Colors.purple.shade600,
                          backgroundColor: Colors.indigo.shade700,
                          side: BorderSide(
                            color: _selectedCategory == category
                                ? Colors.purple.shade400
                                : Colors.indigo.shade600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Trophy Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTrophies,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredTrophies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No trophies found',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTrophies.length,
                            itemBuilder: (context, index) {
                              final item = filteredTrophies[index];
                              if (item is UserTrophy) {
                                return TrophyCard(
                                  trophy: item.trophy,
                                  isUnlocked: true,
                                  unlockedAt: item.unlockedAt,
                                );
                              } else {
                                final trophy = item as Trophy;
                                return TrophyCard(
                                  trophy: trophy,
                                  isUnlocked: false,
                                  progress: trophy.currentProgress ?? 0,
                                );
                              }
                            },
                          ),
          ),

          const GameFooter(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade700.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _selectedFilter == value ? Colors.white : Colors.white70,
          ),
        ),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = value);
          }
        },
        selectedColor: Colors.amber.shade700,
        backgroundColor: Colors.indigo.shade700,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: _selectedFilter == value
              ? Colors.amber.shade600
              : Colors.indigo.shade600,
        ),
      ),
    );
  }
}
