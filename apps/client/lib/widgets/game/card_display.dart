import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      child: Center(
        child: SizedBox(
          height: 500,
          width: 350, // Fixed width based on 0.7 aspect ratio
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
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
      ),
    );
  }

  Widget _buildCroppedCard() {
    if (widget.croppedImage == null) return const SizedBox.shrink();

    // Strip the data URL prefix if present (e.g., "data:image/png;base64,")
    String base64String = widget.croppedImage!;
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E), // Dark Indigo
            Color(0xFF0D47A1), // Dark Blue
            Color(0xFF000051), // Deep Blue
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Stack(
        children: [
          // Mystery Question Mark
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/interogation.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Progressive Reveal Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.memory(
              base64Decode(base64String),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.transparent,
                  child: const Center(
                    child: Icon(Icons.error, size: 50, color: Colors.white54),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    if (widget.fullImageUrl == null) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Keep white background to ensure no bleed through
        borderRadius: BorderRadius.circular(20),
      ),
      child: CachedNetworkImage(
        imageUrl: widget.fullImageUrl!,
        fit: BoxFit.cover, // Cover entire container which is now ratio-locked
        placeholder: (context, url) => const SizedBox.shrink(),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, size: 50),
            ),
          );
        },
      ),
    );
  }
}
