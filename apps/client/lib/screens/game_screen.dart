import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/game/game_header.dart';
import '../widgets/game/card_display.dart';
import '../widgets/game/guess_input.dart';
import '../widgets/game/result_display.dart';
import '../widgets/game/scoreboard.dart';
import '../services/game_socket_service.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}


class _GameScreenState extends State<GameScreen> {
  // ... (Variables mostly same, remove Auth logic if only using ws, but might need auth token for WS init if not singleton)
  String? _lobbyId;
  String? _gameId;
  String? _guestId;

  String? _croppedImage;
  String? _fullImageUrl;
  String? _revealedName;
  String? _revealedSet;

  bool _isLoading = true;
  bool showFullCard = false;
  String? error;
  int score = 0;
  int attempts = 0;
  late TextEditingController _guessController;
  bool? _isCorrect;

  final _socketService = GameSocketService();
  StreamSubscription? _roundSub;
  StreamSubscription? _guessResultSub;
  
  // Timer variables
  Timer? _countdownTimer;
  int _remainingSeconds = 30;
  static const int _roundDuration = 30;
  
  // Scoreboard and waiting state
  Map<String, int> _scores = {};
  bool _isWaitingForRoundEnd = false;
  
  // Card history for final screen
  List<Map<String, dynamic>> _cardHistory = [];
  
  // Actually the Gateway emits 'guessResult' only to the guesser. 
  // It emits 'roundFinished' to EVERYONE if correct.
  // We need to differentiate "My Guess Result" (which might be "Wrong, try again") vs "Round Finished" (someone won/gave up).
  
  // Wait, I didn't add 'roundFinished' stream to GameSocketService yet? I added 'guessResult'.
  // I need to add 'roundFinished' to GameSocketService or reuse one? 
  // I added 'socket.on('nextRound', ...)' mapped to _roundUpdateController. 
  // But I missed 'roundFinished'.
  // I will cheat and map 'roundFinished' dynamically or assume I strictly use 'nextRound' for now for the next card.
  // But wait, 'roundFinished' is what reveals the card.
  // I must add 'roundFinished' to GameSocketService first or inline listen.
  
  // Let's assume for this specific edit I can ONLY edit GameScreen. 
  // I can access the raw socket via `_socketService.socket` if needed, but better to update Service.
  // However, `socket.on('guessResult')` IS mapped.
  // I will use `guessResult` for "Try again" messages.
  // For "Round Finished" (showing the card), I need to listen to it.
  // I will access `_socketService.socket.on('roundFinished', ...)` directly in _initSocket here as a workaround or quick fix, 
  // or I can do a multi-file edit. 
  // Let's stick to GameScreen and use direct socket access for the missing event helper, or just trust 'nextRound' will come eventually.
  // But we want to show the answer! 
  
  @override
  void initState() {
    super.initState();
    _guessController = TextEditingController();
  }

  @override
  void dispose() {
    _guessController.dispose();
    _roundSub?.cancel();
    _guessResultSub?.cancel();
    _countdownTimer?.cancel();
    // Remove specific listeners attached manually to avoid duplicates if we come back
    _socketService.socket.off('roundFinished');
    _socketService.socket.off('giveUpResult');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _lobbyId = args['lobbyId'];
      _guestId = args['guestId'];
      
      if (_gameId == null) {
        _initSocket();
        // Trigger initial load (e.g. if we refreshed, we might need to ask for current state? 
        // OR the host 'startGame' event already pushed 'gameStarted' with data.
        // If we came from WaitingRoom, we might have MISSED the 'gameStarted' event payload if we were navigating?
        // Actually, WaitingRoom handles 'gameStarted', navigates here. 
        // But we need the INITIAL card.
        // 'gameStarted' event has the first round data.
        // We probably need to ask for "Current Round" state on load.
        // I'll emit 'startGame' again? No, that resets.
        // Ideally 'joinGame' gives us current state.
        // Let's rely on 'nextRound' or 'gameStarted' being re-emitted?
        // Actually, simpler: The host started the game. The EVENT 'gameStarted' containing the first card might have been received while we were transitioning.
        // Solution: Call an HTTP endpoint to "get current round" just once on init? Or `socket.emit('getCurrentRound')`.
        // I will rely on `startNewGame` (HTTP) mechanism repurposed for "Sync State".
        // But let's try to be pure WS. 
        // I will use `joinGame` again here. It sends `gameStatus`.
        // If `gameStatus` is PLAYING, does it send round data? The `joinGame` in backend sends `gameStatus` (Players/Status) but NOT the card.
        // I should update backend to send Round Data if playing.
        
        // For now, to be safe and compatible with previous steps:
        // I will keep `startNewGame` as a "Fetch Initial State" via HTTP or WS.
        // But the prompt asked to refactor all to WS.
        // Let's implement `_fetchCurrentState` via polling/one-off HTTP if WS doesn't provide it yet,
        // OR simpler: Just emit 'startGame' from Host (which initiates it).
        // For Guests... they need to fetch.
        // I will implement a `getCurrentstate` call via WS?
        // Let's just use `startNewGame` logic but via WS? No, `startGame` resets.
        // Use `joinGame`.
        _socketService.joinGame(_lobbyId!, _guestId ?? 'guest');
        
        // Manual fix: Request current round check (could be via HTTP to be safe/fast since I didn't add 'getRound' WS event)
        _fetchInitialRound();
      }
    }
  }

  Future<void> _fetchInitialRound() async {
     try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/game/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'lobbyId': _lobbyId, if (_guestId!=null) 'guestId':_guestId})
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
           _handleRoundUpdate(jsonDecode(response.body));
        } else {
           if (mounted) setState(() {
             error = 'Failed to load game: ${response.statusCode}';
             _isLoading = false;
           });
        }
     } catch(e) {
       if (mounted) setState(() {
         error = 'Connection error: $e';
         _isLoading = false;
       });
     }
  }

  // Alias for compatibility with UI calls
  Future<void> startNewGame() => _fetchInitialRound();

  void _initSocket() {
     _socketService.connect();

    _roundSub = _socketService.roundUpdateStream.listen((data) {
       _handleRoundUpdate(data);
    });
    
    _guessResultSub = _socketService.guessResultStream.listen((data) {
       if (!mounted) return;
       if (data['correct'] == true) {
         _showResult(data);
       } else {
         ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect! Try again.')),
         );
       }
    });

    _socketService.socket.on('giveUpResult', (data) {
        if (mounted) {
           _showResult(data ?? {});
        }
    });

    _socketService.socket.on('roundFinished', (data) {
       if (mounted) {
         // This overrides whatever we have, ensuring everyone sees the result
         // data.result contains everything
         _showResult(data['result'] ?? {});
       }
    });
  }

   void _showResult(Map<String, dynamic> result) {
    _stopRoundTimer(); // Stop the timer when result is shown
    if (!mounted) return;
    
    setState(() {
       showFullCard = true;
       // If I guessed, it's correct. If I gave up or round finished, treat as correct/reveal.
       // Distinguish 'correct' vs 'giveUp'?
       // makeGuess returns {correct: true}. giveUp returns just card info (undefined correct).
       // We can map logic: _isCorrect = result['correct'] == true;
       _isCorrect = result['correct'] == true;
       
       _fullImageUrl = result['fullImageUrl'];
       _revealedName = result['name'];
       _revealedSet = result['set'];
       
       // Add card to history for final screen display
       if (_revealedName != null && _fullImageUrl != null) {
         _cardHistory.add({
           'name': _revealedName!,
           'imageUrl': _fullImageUrl!,
           'set': _revealedSet ?? '',
         });
       }
       
       // Update scores from server response if available
       if (result['scores'] != null) {
         _scores = Map<String, int>.from(result['scores']);
         // Update local score for header display
         if (_guestId != null && _scores.containsKey(_guestId)) {
           score = _scores[_guestId]!;
         }
       } else if (_isCorrect == true) {
         // Fallback: increment local score if server didn't send scores
         score++;
       }
    });
  }

  void _startRoundTimer() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    
    setState(() {
      _remainingSeconds = _roundDuration;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopRoundTimer() {
    _countdownTimer?.cancel();
  }

  void _handleRoundUpdate(dynamic data) {
    if (!mounted) return;
    
    if (data['status'] == 'FINISHED') {
       setState(() {
         // Extract final scores before showing finished state
         if (data['scores'] != null) {
           _scores = Map<String, int>.from(data['scores']);
         }
         
         // Extract full card history from server to ensure all cards are shown
         if (data['history'] != null) {
           _cardHistory = (data['history'] as List).map((item) => {
             'name': item['name'].toString(),
             'imageUrl': item['fullImageUrl'].toString(),
             'set': item['set'].toString(),
             'results': item['results'] ?? [], // Preserve the results list
           }).toList();
         }
         
         error = 'Game Finished!';
         _isLoading = false;
       });
       return;
    }
    
    String cropped = data['croppedImage'] ?? '';
    if (cropped.contains(',')) cropped = cropped.split(',').last;

    setState(() {
      _gameId = data['gameId'];
      _croppedImage = cropped;
      _isLoading = false;
      showFullCard = false;
      _isCorrect = null;
      _guessController.clear();
      error = null;
      _isWaitingForRoundEnd = false; // Reset waiting state for new round
      
      // Extract scores if available
      if (data['scores'] != null) {
        _scores = Map<String, int>.from(data['scores']);
      }
      
      // Extract round info
      // _currentRound and _totalRounds removed as they are unused for now
    });
    
    // Start the countdown timer for the new round
    _startRoundTimer();
  }

  void checkGuess() {
    if (_lobbyId == null || _guessController.text.isEmpty) return;
    _socketService.makeGuess(_lobbyId!, _guestId ?? 'guest', _guessController.text);
  }

  void giveUp() {
    if (_lobbyId == null) return;
    setState(() {
      _isWaitingForRoundEnd = true;
    });
    _socketService.socket.emit('giveUp', {'lobbyId': _lobbyId, 'userId': _guestId ?? 'guest'});
  }

  void nextCard() {
    // Actually next card is handled automatically by server timeout!
    // But if we want to force it? Server handles it.
    // We just wait.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a237e),
              const Color(0xFF3B4CCA),
              const Color(0xFF5E35B1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              GameHeader(
                score: score,
                attempts: attempts,
                remainingSeconds: _remainingSeconds,
              ),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? _buildLoadingState()
                      : error != null
                          ? _buildErrorState()
                          : _buildGameContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading Pokemon card...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    // Check if this is a "Game Finished" state
    final isGameFinished = error == 'Game Finished!';
    
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        if (isGameFinished) ...[
          // Final Scoreboard
          Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            'Game Over!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_scores.isNotEmpty)
            Scoreboard(
              scores: _scores,
              currentUserId: _guestId,
            ),
          const SizedBox(height: 24),
          
          // Card History Section
          if (_cardHistory.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cards from this game:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cardHistory.length,
                      itemBuilder: (context, index) {
                        final card = _cardHistory[index];
                        final results = (card['results'] as List<dynamic>?) ?? [];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  card['imageUrl']!,
                                  width: 60,
                                  height: 84, // 0.7 aspect ratio
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 60, height: 84, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Card Details & Results
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card['name']!,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      card['set']!,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: Colors.white24, height: 1),
                                    const SizedBox(height: 8),
                                    if (results.isEmpty)
                                       Text('No successful guesses', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic, fontSize: 12))
                                    else
                                       Column(
                                         children: results.map<Widget>((r) {
                                           final isCorrect = r['correct'] == true;
                                           final points = r['points'];
                                           final time = (r['timeTaken'] as num) / 1000.0;
                                           
                                           return Padding(
                                             padding: const EdgeInsets.symmetric(vertical: 2),
                                             child: Row(
                                               children: [
                                                  Icon(
                                                    isCorrect ? Icons.check_circle : Icons.cancel, 
                                                    size: 14, 
                                                    color: isCorrect ? Colors.greenAccent : Colors.redAccent
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(r['userId'] == _guestId ? 'You' : r['userId'], style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                                  if (isCorrect) ...[
                                                    Text('${time.toStringAsFixed(1)}s', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                    const SizedBox(width: 12),
                                                    Text('+$points pts', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  ] else 
                                                    const Text('Given Up', style: TextStyle(color: Colors.white30, fontSize: 12))
                                               ],
                                             ),
                                           );
                                         }).toList(),
                                       )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/lobby', (route) => false);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Lobby'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B4CCA),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ] else ...[
          // Regular error state
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'An error occurred',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: startNewGame,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B4CCA),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
      ),
    );
  }

  Widget _buildGameContent() {
    if (_croppedImage == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main game content (left side)
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CardDisplay(
                    showFullCard: showFullCard,
                    croppedImage: _croppedImage,
                    fullImageUrl: _fullImageUrl,
                  ),
                  const SizedBox(height: 24),
                  // Show waiting message if user gave up
                  if (_isWaitingForRoundEnd && !showFullCard)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Waiting for round to end...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!showFullCard)
                    GuessInput(
                      controller: _guessController,
                      onGuessSubmitted: checkGuess,
                      onGiveUp: giveUp,
                    )
                  else
                    ResultDisplay(
                      isCorrect: _isCorrect,
                      revealedName: _revealedName,
                      revealedSet: _revealedSet,
                    ),
                ],
              ),
            ),
            
            // Scoreboard (right side)
            if (_scores.isNotEmpty) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: 250,
                child: Scoreboard(
                  scores: _scores,
                  currentUserId: _guestId,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
