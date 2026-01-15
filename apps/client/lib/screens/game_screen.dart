import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokecardguess/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;

import '../widgets/game/game_header.dart';
import '../widgets/game/card_display.dart';
import '../widgets/game/guess_input.dart';
import '../widgets/game/result_display.dart';
import '../widgets/game/scoreboard.dart';
import '../widgets/game/story_share_card.dart';
import '../services/game_socket_service.dart';
import '../services/auth_storage_service.dart';
import '../widgets/trophy/trophy_toast.dart';
import '../../models/trophy.dart';

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
  final ScreenshotController _screenshotController = ScreenshotController();
  StreamSubscription? _roundSub;
  StreamSubscription? _guessResultSub;
  StreamSubscription? _scoreboardSub;
  
  // Timer variables
  Timer? _countdownTimer;
  int _remainingSeconds = 30;
  static const int _roundDuration = 30;


  void _shareSystem(Uint8List image) async {
    try {
      final xFile = XFile.fromData(
        image,
        name: 'pokecardguess_story.png',
        mimeType: 'image/png',
      );
      
      await Share.shareXFiles(
        [xFile],
        text: 'I just scored $score points in PokeCardGuess! Can you beat me? 🃏✨ #Pokemon #PokeCardGuess ${AppConfig.clientUrl}',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  Future<void> _shareStoryImage() async {
    try {
      if (score == 0 && _cardHistory.isEmpty) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Precache assets to ensure they appear in screenshot
      if (mounted) {
        await precacheImage(const AssetImage('assets/images/landscape.png'), context);
        await precacheImage(const AssetImage('assets/images/pokecardguess.png'), context);
      }

      // Capture the off-screen widget
      final image = await _screenshotController.captureFromWidget(
        Material(
          child: StoryShareCard(
            score: score,
            cardHistory: _cardHistory,
            userName: _playerNames[_guestId ?? ''] ?? 'Guest',
            userPicture: null, 
          ),
        ),
        delay: const Duration(milliseconds: 1000), // Increased delay for Web asset loading
        pixelRatio: 2.0,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show Preview Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.indigo.shade900,
          title: const Text('Share Story', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: 600,
                  ),
                  child: Image.memory(image),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                         _downloadImage(image);
                         Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                         _shareSystem(image);
                         Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share via System'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                         _shareOnX();
                         Navigator.pop(ctx);
                      },
                      icon: const FaIcon(FontAwesomeIcons.xTwitter, size: 16),
                      label: const Text('Post Score on X'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Close loading if active
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating image: $e')),
        );
      }
    }
  }

  void _downloadImage(Uint8List image) {
      final blob = html.Blob([image]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'pokecardguess_story.png')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved! Ready to post on Instagram stories! 📸')),
      );
  }

  void _shareOnX() {
      final text = Uri.encodeComponent('I just scored $score points in PokeCardGuess! Can you beat me? 🃏✨\n\nPlay now: ${AppConfig.clientUrl}\n\n#Pokemon #PokeCardGuess');
      final url = Uri.parse('https://x.com/intent/post?text=$text');
      launchUrl(url, mode: LaunchMode.externalApplication);
  }
  
  // Scoreboard and waiting state
  Map<String, int> _scores = {};
  Map<String, String> _playerStatuses = {};
  Map<String, String> _playerNames = {};
  bool _isWaitingForRoundEnd = false;
  
  int _currentRound = 0;
  int _totalRounds = 0;
  
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
  
  // Trophy Queue System
  final Queue<dynamic> _trophyQueue = Queue<dynamic>();
  bool _isProcessingTrophies = false;

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
    _scoreboardSub?.cancel();
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

    if (args == null || args['lobbyId'] == null) {
       WidgetsBinding.instance.addPostFrameCallback((_) async {
         final token = await AuthStorageService().getToken();
         final guestName = await AuthStorageService().getGuestName();
         if (context.mounted) {
           Navigator.of(context).pushReplacementNamed('/lobby', arguments: {
             'authToken': token,
             if (guestName != null) 'guestName': guestName,
           });
         }
       });
       return;
    }

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
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/game/$_lobbyId/round'),
        );
        if (response.statusCode == 200) {
           _handleRoundUpdate(jsonDecode(response.body));
        } else {
           if (mounted) setState(() {
             error = 'Failed to load game round: ${response.statusCode}';
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
       
       // Real-time trophy unlocking check
       if (data['unlockedTrophies'] != null) {
         final trophies = data['unlockedTrophies'] as List;
         if (trophies.isNotEmpty) {
           _showTrophyCelebration(trophies);
         }
       }
       
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

    _socketService.socket.on('progressiveReveal', (data) {
       if (mounted) {
         setState(() {
           if (data['croppedImage'] != null) {
             _croppedImage = data['croppedImage'];
           }
         });
       }
    });

    _scoreboardSub = _socketService.scoreboardUpdateStream.listen((data) {
       if (mounted) {
         setState(() {
           if (data['scores'] != null) {
              _scores = Map<String, int>.from(data['scores']);
              if (_guestId != null && _scores.containsKey(_guestId)) {
                score = _scores[_guestId]!;
              }
           }
           if (data['playerStatuses'] != null) {
              if (data['playerStatuses'] is List) {
                _playerStatuses = {};
                for (var item in data['playerStatuses']) {
                  final userId = item['userId'] as String;
                  _playerNames[userId] = item['name']?.toString() ?? 'Player';
                  _playerStatuses[userId] = item['status']?.toString() ?? 'thinking';
                }
              } else {
                _playerStatuses = Map<String, String>.from(data['playerStatuses']);
              }
           }
         });
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
       
       if (result['playerStatuses'] != null) {
          if (result['playerStatuses'] is List) {
            _playerStatuses = {};
            for (var item in result['playerStatuses']) {
              final userId = item['userId'] as String;
              _playerNames[userId] = item['name']?.toString() ?? 'Player';
              _playerStatuses[userId] = item['status']?.toString() ?? 'thinking';
            }
          } else {
            _playerStatuses = Map<String, String>.from(result['playerStatuses']);
          }
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

         if (data['playerNames'] != null) {
           _playerNames = Map<String, String>.from(data['playerNames']);
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

       // Check for unlocked trophies
       if (data['unlockedTrophies'] != null) {
          final trophiesMap = data['unlockedTrophies'];
          if (_guestId != null && trophiesMap[_guestId] != null) {
             final myTrophies = trophiesMap[_guestId] as List;
             if (myTrophies.isNotEmpty) {
                 _showTrophyCelebration(myTrophies);
             }
          }
       }
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

      if (data['playerStatuses'] != null) {
        if (data['playerStatuses'] is List) {
          _playerStatuses = {};
          for (var item in data['playerStatuses']) {
            final userId = item['userId'] as String;
            _playerNames[userId] = item['name']?.toString() ?? 'Player';
            // storing status string based on backend status
            _playerStatuses[userId] = item['status']?.toString() ?? 'thinking';
          }
        } else {
           _playerStatuses = Map<String, String>.from(data['playerStatuses']);
        }
      }
      
      // Extract round info
      _currentRound = data['round'] ?? 0;
      _totalRounds = data['totalRounds'] ?? 0;
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
    _socketService.giveUp(_lobbyId!, _guestId ?? 'guest');
  }

  void nextCard() {
    // Actually next card is handled automatically by server timeout!
    // But if we want to force it? Server handles it.
    // We just wait.
  }

  void _showTrophyCelebration(List<dynamic> trophyDataList) {
    for (var trophyData in trophyDataList) {
      _trophyQueue.add(trophyData);
    }
    _processTrophyQueue();
  }

  Future<void> _processTrophyQueue() async {
    if (_isProcessingTrophies) return;
    _isProcessingTrophies = true;

    while (_trophyQueue.isNotEmpty && mounted) {
      final trophyData = _trophyQueue.removeFirst();
      
      try {
        final Map<String, dynamic> dataMap = trophyData as Map<String, dynamic>;
        // Backend returns UserTrophy which contains 'trophy'. Extract it if present.
        final trophyJson = dataMap['trophy'] != null ? dataMap['trophy'] : dataMap;
        
        final trophy = Trophy.fromJson(trophyJson);
        final completer = Completer<void>();
        late OverlayEntry overlayEntry;
        
        overlayEntry = OverlayEntry(
          builder: (context) => TrophyUnlockToast(
            trophy: trophy,
            onDismiss: () {
              overlayEntry.remove();
              completer.complete();
            },
          ),
        );
        
        // Use rootOverlay: true to show above everything
        Overlay.of(context, rootOverlay: true).insert(overlayEntry);
        await completer.future;
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Error showing trophy toast: $e');
      }
    }
    
    _isProcessingTrophies = false;
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
                currentRound: _currentRound,
                totalRounds: _totalRounds,
                remainingSeconds: (error == 'Game Finished!') ? null : _remainingSeconds,
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

    if (!isGameFinished) {
      // Regular error state (just centered icon and text)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'Unknown Error',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final token = await AuthStorageService().getToken();
                final guestName = await AuthStorageService().getGuestName();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/lobby',
                    (route) => false,
                    arguments: {
                      'authToken': token,
                      if (guestName != null) 'guestName': guestName,
                    },
                  );
                }
              },
              child: const Text('Back to Lobby'),
            ),
          ],
        ),
      );
    }

    // Game Finished State
    final content = SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Final Scoreboard Header
          const Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          const Text(
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
              playerNames: _playerNames,
              onShare: _shareStoryImage,
            ),
          const SizedBox(height: 24),
          
          // Card History Section
          if (_cardHistory.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  card['imageUrl']!,
                                  width: 60,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 60, height: 84, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: Colors.white24, height: 1),
                                    const SizedBox(height: 8),
                                    if (results.isEmpty)
                                       Text('No successful guesses', style: TextStyle(color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic, fontSize: 12))
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
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(r['userId'] == _guestId ? 'You' : r['userId'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                                        if (r['guess'] != null)
                                                          Text(
                                                            '${r['guess']}',
                                                            style: TextStyle(
                                                              color: isCorrect ? Colors.greenAccent.withOpacity(0.8) : Colors.white38,
                                                              fontSize: 12,
                                                              fontStyle: FontStyle.italic
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isCorrect) ...[
                                                    Text('${time.toStringAsFixed(1)}s', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                                    const SizedBox(width: 12),
                                                    Text('+$points pts', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  ] else 
                                                    const Text('Failed', style: TextStyle(color: Colors.white30, fontSize: 12))
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

        ],
      ),
    );

    return Column(
      children: [
        Expanded(child: content),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: const Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final token = await AuthStorageService().getToken();
                  final guestName = await AuthStorageService().getGuestName();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/lobby',
                      (route) => false,
                      arguments: {
                        'authToken': token,
                        if (guestName != null) 'guestName': guestName,
                      },
                    );
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.indigo),
                label: const Text('Back to Lobby', style: TextStyle(color: Colors.indigo)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent() {
    if (_croppedImage == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        final gameContentWidget = Column(
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
        );

        final scoreboardWidget = Scoreboard(
          scores: _scores,
          currentUserId: _guestId,
          playerStatuses: _playerStatuses,
          playerNames: _playerNames,
        );

        if (isMobile) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  gameContentWidget,
                  if (_scores.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    scoreboardWidget,
                  ],
                ],
              ),
            ),
          );
        } else {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: gameContentWidget,
                  ),
                  if (_scores.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: scoreboardWidget,
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
