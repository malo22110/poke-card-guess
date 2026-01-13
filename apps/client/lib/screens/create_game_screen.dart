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
  String _selectedSetId = '151'; // Default
  List<dynamic> _availableSets = [];
  bool _isLoadingSets = true;
  bool _isCreating = false;
  String? _error;
  String? _authToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _authToken = args['authToken'];
    }
    // Fetch sets only if we haven't done so or if auth token just arrived (re-trigger)
    if (_availableSets.isEmpty) {
      _fetchSets();
    }
  }

  @override
  void initState() {
    super.initState();
    // Moved fetchSets to didChangeDependencies to ensure context/args are available
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

  Future<void> _createGame() async {
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
          'sets': [_selectedSetId],
          'secretOnly': _secretOnly,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final lobbyId = data['id'];
        final guestId = data['hostId']; // Extract guest ID if available
        
        if (mounted) {
           Navigator.of(context).pushReplacementNamed('/waiting-room', arguments: {
              'lobbyId': lobbyId,
               'isHost': true,
               'authToken': widget.authToken,
               'guestId': guestId, // Pass guest ID
           });
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
        child: _isLoadingSets
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
                _buildSetsGrid(),
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

  Widget _buildSetsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _availableSets.length,
      itemBuilder: (context, index) {
        final set = _availableSets[index];
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
                if (set['logo'] != null && set['logo'].toString().endsWith('png'))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        set['logo'] + '.png', // Some APIs might need extension?
                        errorBuilder: (c, o, s) => const Icon(Icons.image, color: Colors.white24),
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
        child: ElevatedButton(
          onPressed: _isCreating ? null : _createGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isCreating
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('START GAME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}
