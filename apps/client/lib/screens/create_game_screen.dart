import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateGameScreen extends StatefulWidget {
  final String? authToken;

  const CreateGameScreen({super.key, this.authToken});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  double _rounds = 10;
  bool _secretOnly = true;
  String? _selectedSetId; // No default, user must select
  List<dynamic> _availableSets = [];
  List<String> _availableRarities = [];
  List<String> _selectedRarities = [];
  bool _isLoadingSets = true;
  bool _isLoadingRarities = true;
  bool _isCreating = false;
  String? _error;
  String? _authToken;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Define common rarities to exclude by default
  final List<String> _commonRarities = [
    'Commune',
    'Peu Commune',
    'Rare',
    'Rare Holo',
    'Holo Rare',
    'Sans Rareté',
    'Un Diamant',
    'Deux Diamants',
    'Trois Diamants',
    'Quatre Diamants',
    'Une Étoile',
    'Deux Étoiles',
    'Trois Étoiles',
    'Couronne',
    'Double rare',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _authToken = args['authToken'];
    }
    // Fetch sets and rarities only if we haven't done so
    if (_availableSets.isEmpty) {
      _fetchSets();
    }
    if (_availableRarities.isEmpty) {
      _fetchRarities();
    }
  }

  @override
  void initState() {
    super.initState();
    // Moved fetchSets to didChangeDependencies to ensure context/args are available
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Getter for filtered sets based on search query
  List<dynamic> get _filteredSets {
    if (_searchQuery.isEmpty) {
      return _availableSets;
    }
    return _availableSets.where((set) {
      final name = set['name'].toString().toLowerCase();
      final id = set['id'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();
  }

  Future<void> _fetchSets() async {
    try {
      // Fetch sets from backend
      // Note: Assuming optional auth guard allows access or we pass token if available
       final response = await http.get(
        Uri.parse('http://localhost:3000/game/sets'),
        headers: widget.authToken != null 
          ? {'Authorization': 'Bearer ${widget.authToken}'}
          : {},
      );

      if (response.statusCode == 200) {
        setState(() {
          _availableSets = jsonDecode(response.body);
          _isLoadingSets = false;
        });
      } else {
        throw Exception('Failed to load sets');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load sets: $e';
        _isLoadingSets = false;
      });
    }
  }

  Future<void> _fetchRarities() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/game/rarities'),
        headers: widget.authToken != null 
          ? {'Authorization': 'Bearer ${widget.authToken}'}
          : {},
      );

      if (response.statusCode == 200) {
        final List<dynamic> rarities = jsonDecode(response.body);
        setState(() {
          _availableRarities = rarities.cast<String>();
          // Auto-select special rarities by default
          _selectSpecialRarities();
          _isLoadingRarities = false;
        });
      } else {
        throw Exception('Failed to load rarities');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load rarities: $e';
        _isLoadingRarities = false;
      });
    }
  }

  void _selectSpecialRarities() {
    setState(() {
      _selectedRarities = _availableRarities
          .where((rarity) => !_commonRarities.contains(rarity))
          .toList();
    });
  }

  void _selectAllRarities() {
    setState(() {
      _selectedRarities = List.from(_availableRarities);
    });
  }

  void _clearRarities() {
    setState(() {
      _selectedRarities = [];
    });
  }

  Future<void> _createGame() async {
    if (_selectedSetId == null) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/game/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'rounds': _rounds.toInt(),
          'sets': [_selectedSetId!],
          'secretOnly': _secretOnly,
          'rarities': _secretOnly && _selectedRarities.isNotEmpty 
              ? _selectedRarities 
              : null,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final lobbyId = data['id'];
        final guestId = data['hostId']; // Extract guest ID if available
        
        if (mounted) {
           final uri = Uri(path: '/waiting-room', queryParameters: {
             'lobbyId': lobbyId.toString(),
             'isHost': 'true',
             if (guestId != null) 'guestId': guestId.toString(),
           });
           Navigator.of(context).pushReplacementNamed(
             uri.toString(), 
             arguments: {'authToken': widget.authToken}
           );
        }
      } else {
        throw Exception('Failed to create game: ${response.body}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
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
        child: (_isLoadingSets || _isLoadingRarities)
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                
                // Configuration Section
                _buildSectionTitle('Game Settings'),
                const SizedBox(height: 16),
                _buildConfigCard(),
                const SizedBox(height: 32),

                // Set Selection Section
                _buildSectionTitle('Select Card Set'),
                const SizedBox(height: 16),
                _buildSearchInput(),
                const SizedBox(height: 16),
                _buildSetsGrid(),
                const SizedBox(height: 32),

                // Rarities Selection Section (only show if secretOnly is enabled)
                if (_secretOnly) ...[
                  _buildSectionTitle('Select Rarities'),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedRarities.length} rarities selected',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildRaritiesSection(),
                ],
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.refresh, color: Colors.white70),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rounds: ${_rounds.round()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Text('Number of cards to guess', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          Slider(
            value: _rounds,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: Colors.amber,
            onChanged: (value) => setState(() => _rounds = value),
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_off, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secret Cards Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Hide card details', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _secretOnly,
                onChanged: (value) => setState(() => _secretOnly = value),
                activeColor: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search sets by name or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSetsGrid() {
    // Show empty state if no sets match the search
    if (_filteredSets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sets found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredSets.length,
      itemBuilder: (context, index) {
        final set = _filteredSets[index];
        final isSelected = _selectedSetId == set['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedSetId = set['id']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (set['logo'] != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        set['logo'].toString().endsWith('.png') 
                            ? set['logo'] 
                            : '${set['logo']}.png',
                        errorBuilder: (c, o, s) => const Icon(Icons.image, color: Colors.white24),
                        fit: BoxFit.contain,
                      )
                    ),
                  )
                else 
                  const Expanded(child: Icon(Icons.album, size: 40, color: Colors.white54)),
                
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    set['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a237e).withOpacity(0.9),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: (_isCreating || _selectedSetId == null) ? null : _createGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isCreating
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                        SizedBox(width: 12),
                        Text('Fetching random cards...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text('CREATE GAME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaritiesSection() {
    if (_isLoadingRarities) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preset Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetButton(
                'Special Only',
                Icons.star,
                _selectSpecialRarities,
              ),
              _buildPresetButton(
                'All Rarities',
                Icons.select_all,
                _selectAllRarities,
              ),
              _buildPresetButton(
                'Clear All',
                Icons.clear,
                _clearRarities,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          
          // Rarities Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableRarities.map((rarity) {
              final isSelected = _selectedRarities.contains(rarity);
              final isCommon = _commonRarities.contains(rarity);
              
              return FilterChip(
                label: Text(
                  rarity,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedRarities.add(rarity);
                    } else {
                      _selectedRarities.remove(rarity);
                    }
                  });
                },
                backgroundColor: isCommon 
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.purple.withOpacity(0.3),
                selectedColor: Colors.amber,
                checkmarkColor: Colors.black,
                side: BorderSide(
                  color: isSelected 
                      ? Colors.amber 
                      : (isCommon ? Colors.grey : Colors.purple).withOpacity(0.5),
                  width: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
