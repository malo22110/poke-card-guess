import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokecardguess/config/app_config.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
class CreateGameScreen extends StatefulWidget {
  final String? authToken;

  const CreateGameScreen({super.key, this.authToken});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Custom Config State
  double _rounds = 10;
  bool _secretOnly = true;
  List<String> _selectedSetIds = [];
  List<dynamic> _availableSets = [];
  List<String> _availableRarities = [];
  List<String> _selectedRarities = [];
  
  // Preview State
  List<dynamic> _previewCards = [];
  bool _isLoadingPreview = false;
  Timer? _debounce;
  
  // Game Modes State
  List<dynamic> _gameModes = [];
  String? _selectedGameModeId;
  bool _isLoadingGameModes = true;
  
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
  void initState() {
    super.initState();
    _authToken = widget.authToken;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _authToken = args['authToken'];
    }

    // Guard: Prevent guests from accessing this screen
    if (_authToken == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to create a game.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }

    // Fetch data only if we haven't done so
    if (_availableSets.isEmpty) {
      _fetchSets();
    }
    if (_availableRarities.isEmpty) {
      _fetchRarities();
    }
    if (_gameModes.isEmpty) {
      _fetchGameModes();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchGameModes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes'),
        headers: _authToken != null 
          ? {'Authorization': 'Bearer $_authToken'}
          : {},
      );

      if (response.statusCode == 200) {
        setState(() {
          _gameModes = jsonDecode(response.body);
          _isLoadingGameModes = false;
        });
      }
    } catch (e) {
      print('Failed to fetch game modes: $e');
      setState(() => _isLoadingGameModes = false);
    }
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
        Uri.parse('${AppConfig.apiBaseUrl}/game/sets'),
        headers: _authToken != null 
          ? {'Authorization': 'Bearer $_authToken'}
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
        Uri.parse('${AppConfig.apiBaseUrl}/game/rarities'),
        headers: _authToken != null 
          ? {'Authorization': 'Bearer $_authToken'}
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

  void _debouncedFetchPreview() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _fetchPreviewCards);
  }

  Future<void> _fetchPreviewCards() async {
    if (!mounted) return;
    
    // Don't fetch if filter is invalid (no sets, etc, unless filtering rules allow empty sets = all?)
    // GameService supports empty sets to mean filtered by rarity only? No, getPreviewCards checks. 
    // And if sets is not empty.
    
    setState(() {
      _isLoadingPreview = true;
    });

    try {
      final body = {
        'sets': _selectedSetIds,
        'rarities': _selectedRarities,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/game/preview-cards'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() {
            _previewCards = jsonDecode(response.body);
            _isLoadingPreview = false;
          });
        }
      } else {
        throw Exception('Failed to load preview');
      }
    } catch (e) {
      print('Preview fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoadingPreview = false; 
          // Keep old preview or clear? defaulting to keeping or empty
          // _previewCards = []; 
        });
      }
    }
  }

  void _selectSpecialRarities() {
    setState(() {
      _selectedRarities = _availableRarities
          .where((rarity) => !_commonRarities.contains(rarity))
          .toList();
    });
    _debouncedFetchPreview();
  }

  void _selectAllRarities() {
    setState(() {
      _selectedRarities = List.from(_availableRarities);
    });
    _debouncedFetchPreview();
  }

  void _clearRarities() {
    setState(() {
      _selectedRarities = [];
    });
    _debouncedFetchPreview();
  }

  Future<void> _createGame() async {
    // Validation based on active tab
    if (_tabController.index == 0) {
      if (_selectedGameModeId == null) {
        setState(() => _error = 'Please select a game mode');
        return;
      }
    } else {
      if (_selectedSetIds.isEmpty) {
        setState(() => _error = 'Please select at least one card set');
        return;
      }
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> body = {};
      
      if (_tabController.index == 0) {
        // Preset Mode
        body['gameModeId'] = _selectedGameModeId;
      } else {
        // Custom Mode
        body['rounds'] = _rounds.toInt();
        body['sets'] = _selectedSetIds;
        body['secretOnly'] = _secretOnly;
        if (_secretOnly && _selectedRarities.isNotEmpty) {
          body['rarities'] = _selectedRarities;
        }
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/game/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(body),
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
             arguments: {'authToken': _authToken}
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Game Modes'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPresetsTab(),
            _buildCustomTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Future<void> _deleteGameMode(String gameModeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game Mode'),
        content: const Text('Are you sure you want to delete this game mode?'),
        backgroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel', style: TextStyle(color: Colors.white60))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
     
    if (confirm != true) return;

    if (mounted) setState(() => _isLoadingGameModes = true);
     
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes/$gameModeId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
       
      if (response.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game mode deleted')));
        }
        await _fetchGameModes();
      } else {
        throw Exception('Failed to delete game mode');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoadingGameModes = false);
      }
    }
  }

  Widget _buildPresetsTab() {
    if (_isLoadingGameModes) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_gameModes.isEmpty) {
      return const Center(child: Text('No game modes available', style: TextStyle(color: Colors.white)));
    }

    return Column(
      children: [
        if (_error != null)
           Container(
             padding: const EdgeInsets.all(12),
             color: Colors.red.withOpacity(0.1),
             width: double.infinity,
             child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
           ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _gameModes.length,
            itemBuilder: (context, index) {
              final mode = _gameModes[index];
              final isSelected = _selectedGameModeId == mode['id'];
              final isOfficial = mode['isOfficial'] == true;
              
              final authService = Provider.of<AuthService>(context, listen: false);
              final currentUserId = authService.currentUser?.id;
              final isCreator = currentUserId != null && mode['creatorId'] == currentUserId;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGameModeId = mode['id'];
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isOfficial) 
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                            ),
                          Text(
                            mode['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (!isOfficial)
                            InkWell(
                              onTap: () => _upvoteGameMode(mode['id']),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.thumb_up, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${mode['_count']?['upvotes'] ?? 0}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          if (isCreator)
                             Padding(
                               padding: const EdgeInsets.only(left: 8.0),
                               child: InkWell(
                                 onTap: () => _deleteGameMode(mode['id']),
                                 borderRadius: BorderRadius.circular(12),
                                 child: Padding(
                                   padding: const EdgeInsets.all(4),
                                   child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                 ),
                               ),
                             ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode['description'] ?? 'No description',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      if (mode['creator'] != null)
                        Text(
                          'Created by ${mode['creator']['name']}',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _upvoteGameMode(String id) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upvote modes')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes/$id/upvote'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Toggle optimistic update or just refresh
        _fetchGameModes(); 
      }
    } catch (e) {
      print('Error upvoting: $e');
    }
  }

  Widget _buildCustomTab() {
    if (_isLoadingSets || _isLoadingRarities) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    return SingleChildScrollView(
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
          _buildSectionTitle('Select Card Sets'),
          const SizedBox(height: 8),
          Text(
            '${_selectedSetIds.length} sets selected',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildSearchInput(),
          const SizedBox(height: 16),
          _buildSetsGrid(),
          const SizedBox(height: 32),


          // Rarities Selection Section
          _buildSectionTitle('Select Rarities'),
          const SizedBox(height: 8),
          Text(
            '${_selectedRarities.length} rarities selected',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildRaritiesSection(),
          const SizedBox(height: 32),


          // Preview Section
          if (_selectedSetIds.isNotEmpty) ...[
             _buildSectionTitle('Card Preview'),
             const SizedBox(height: 8),
             Text(
               'Random sample based on current filters',
               style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontStyle: FontStyle.italic),
             ),
             const SizedBox(height: 16),
             _buildPreviewSection(),
             const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_isLoadingPreview) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
           color: Colors.black.withOpacity(0.2),
           borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               CircularProgressIndicator(color: Colors.white),
               SizedBox(height: 12),
               Text('Loading preview...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_previewCards.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
           color: Colors.black.withOpacity(0.2),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.white12),
        ),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              const Icon(Icons.style, color: Colors.white24, size: 48),
              const SizedBox(height: 8),
              Text(
                'No cards found matching filters',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
           ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _previewCards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final card = _previewCards[index];
          return Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      card['image'] ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => Container(color: Colors.grey, child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card['name'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSavePresetDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Game Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Mode Name',
                  hintText: 'e.g., My Awesome Challenge',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Briefly describe rules...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveCustomMode(nameController.text, descriptionController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCustomMode(String name, String description) async {
    if (name.isEmpty) return;

    try {
      final config = {
        'rounds': _rounds.toInt(),
        'sets': _selectedSetIds,
        'secretOnly': _secretOnly,
        if (_secretOnly && _selectedRarities.isNotEmpty)
          'rarities': _selectedRarities,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/gamemodes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'config': config,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game mode saved successfully!')),
        );
        _fetchGameModes(); // Refresh list
        _tabController.animateTo(0); // Switch to Presets tab
      } else {
        throw Exception('Failed to save mode');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mode: $e')),
      );
    }
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
        final isSelected = _selectedSetIds.contains(set['id']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedSetIds.remove(set['id']);
              } else {
                _selectedSetIds.add(set['id']);
              }
            });
            _debouncedFetchPreview();
          },
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final showSaveButton = _tabController.index == 1 && _authToken != null && _selectedSetIds.isNotEmpty;

            final saveButton = OutlinedButton.icon(
              onPressed: _showSavePresetDialog,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save Mode'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: isMobile ? const Size(double.infinity, 50) : null,
              ),
            );

            final createButton = ElevatedButton(
              onPressed: _authToken == null 
                  ? null 
                  : () {
                    if (_isCreating) return null;
                    if (_tabController.index == 0) {
                       return _selectedGameModeId != null ? _createGame : null;
                    } else {
                       return _selectedSetIds.isNotEmpty ? _createGame : null;
                    }
                  }(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: isMobile ? const Size(double.infinity, 50) : null,
              ),
              child: _authToken == null
                  ? const Text('LOGIN TO CREATE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                  : _isCreating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                            SizedBox(width: 12),
                            Text('Fetching...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text('CREATE GAME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            );

            if (isMobile) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  createButton,
                  if (showSaveButton) ...[
                    const SizedBox(height: 12),
                    saveButton,
                  ],
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   if (showSaveButton) saveButton else const SizedBox.shrink(),
                   createButton,
                ],
              );
            }
          },
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
                  _debouncedFetchPreview();
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
