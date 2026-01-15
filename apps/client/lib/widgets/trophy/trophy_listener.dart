import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:pokecardguess/models/trophy.dart';
import 'package:pokecardguess/services/sound_service.dart';
import 'package:pokecardguess/services/trophy_service.dart';
import 'package:pokecardguess/widgets/trophy/trophy_toast.dart';

class TrophyListener extends StatefulWidget {
  final Widget child;

  const TrophyListener({super.key, required this.child});

  @override
  State<TrophyListener> createState() => _TrophyListenerState();
}

class _TrophyListenerState extends State<TrophyListener> {
  final Queue<Trophy> _trophyQueue = Queue<Trophy>();
  bool _isProcessingTrophies = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = TrophyService().trophyUnlockStream.listen((trophies) {
      if (mounted) {
        for (var trophy in trophies) {
          _trophyQueue.add(trophy);
        }
        _processTrophyQueue();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _processTrophyQueue() async {
    if (_isProcessingTrophies) return;
    _isProcessingTrophies = true;

    while (_trophyQueue.isNotEmpty && mounted) {
      final trophy = _trophyQueue.removeFirst();

      try {
        final completer = Completer<void>();
        late OverlayEntry overlayEntry;

        SoundService().playSound(SoundService.trophy);

        overlayEntry = OverlayEntry(
          builder: (context) => TrophyUnlockToast(
            trophy: trophy,
            onDismiss: () {
              overlayEntry.remove();
              completer.complete();
            },
          ),
        );

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
    return widget.child;
  }
}
