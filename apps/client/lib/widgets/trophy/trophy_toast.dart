import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokecardguess/models/trophy.dart';

class TrophyUnlockToast extends StatefulWidget {
  final Trophy trophy;
  final VoidCallback onDismiss;

  const TrophyUnlockToast({
    Key? key,
    required this.trophy,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<TrophyUnlockToast> createState() => _TrophyUnlockToastState();
}

class _TrophyUnlockToastState extends State<TrophyUnlockToast>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: const Offset(0.0, 1.0), // Slide down to visible area
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    _confettiController.play();
    await _animController.forward();
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      await _animController.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50, // Top margin
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Confetti Source
               Positioned(
                 top: 0,
                 child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.amber],
                 ),
               ),
               
               // Card
               Container(
                margin: const EdgeInsets.only(top: 20), // Space for confetti origin
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a237e), Color(0xFF5E35B1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Wrap width
                  children: [
                     // Icon
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: Colors.white.withOpacity(0.1),
                         border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                       ),
                       child: Text(
                         widget.trophy.icon,
                         style: const TextStyle(fontSize: 32),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Flexible(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Row(
                             children: const [
                               Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                               SizedBox(width: 4),
                               Text(
                                 'TROPHY UNLOCKED!',
                                 style: TextStyle(
                                   color: Colors.amber,
                                   fontWeight: FontWeight.w900,
                                   fontSize: 10,
                                   letterSpacing: 1.0,
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 4),
                           Text(
                             widget.trophy.name,
                             style: const TextStyle(
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                               fontSize: 18,
                             ),
                           ),
                           if (widget.trophy.description.isNotEmpty)
                             Padding(
                               padding: const EdgeInsets.only(top: 4.0),
                               child: Text(
                                 widget.trophy.description,
                                 style: TextStyle(
                                   color: Colors.white.withOpacity(0.8),
                                   fontSize: 12,
                                 ),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
