import 'dart:convert';
import 'package:flutter/material.dart';

class CardDisplay extends StatelessWidget {
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
                if (!showFullCard)
                  _buildCroppedCard()
                else
                  _buildFullCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCroppedCard() {
    if (croppedImage == null) return const SizedBox.shrink();

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
              base64Decode(croppedImage!),
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
    if (fullImageUrl == null) return const SizedBox.shrink();
    
    return Image.network(
      fullImageUrl!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 500,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 500,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error, size: 50),
          ),
        );
      },
    );
  }
}
