import 'dart:convert';
import 'package:flutter/material.dart';

class CardDisplay extends StatefulWidget {
  final bool showFullCard;
  final String? croppedImage;
  final String? fullImageUrl;

  const CardDisplay({
    super.key,
    required this.showFullCard,
    required this.croppedImage,
    required this.fullImageUrl,
  });

  @override
  State<CardDisplay> createState() => _CardDisplayState();
}

class _CardDisplayState extends State<CardDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(CardDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when showFullCard changes from false to true
    if (!oldWidget.showFullCard && widget.showFullCard) {
      _animationController.forward();
    } else if (oldWidget.showFullCard && !widget.showFullCard) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'card_display',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Always show cropped card as base
                _buildCroppedCard(),
                
                // Fade in full card on top
                if (widget.showFullCard)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFullCard(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCroppedCard() {
    if (widget.croppedImage == null) return const SizedBox.shrink();

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Show the cropped image at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.memory(
              base64Decode(widget.croppedImage!),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, size: 50),
                  ),
                );
              },
            ),
          ),
          // Gradient overlay at the top to create mystery effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 150, // Leave space for the cropped image
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1a237e),
                    const Color(0xFF1a237e).withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 80,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Who\'s that Pokemon?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    if (widget.fullImageUrl == null) return const SizedBox.shrink();
    
    return Container(
      height: 500, // Fixed height to prevent layout shift
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.7, // Standard Pokemon card aspect ratio
          child: Image.network(
            widget.fullImageUrl!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B4CCA)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, size: 50),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
