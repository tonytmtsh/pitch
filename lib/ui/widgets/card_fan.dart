import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that displays cards in a fan layout with slight arc, overlap, and z-order.
/// Scales responsively on narrow screens.
class CardFan extends StatelessWidget {
  const CardFan({
    super.key,
    required this.children,
    this.cardWidth = 64.0,
    this.maxAngle = 0.3, // Max rotation angle in radians (~17 degrees)
    this.overlapFactor = 0.6, // How much cards overlap (0.6 means 60% overlap)
    this.fanHeight = 120.0, // Height of the fan container
  });

  final List<Widget> children;
  final double cardWidth;
  final double maxAngle;
  final double overlapFactor;
  final double fanHeight;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = cardWidth * 1.4; // Maintain card aspect ratio
    
    // Calculate responsive scaling
    final availableWidth = screenWidth - 32; // Account for padding
    final minCardWidth = 40.0; // Minimum card width
    final maxCardWidth = cardWidth;
    
    // Calculate ideal fan width
    final idealFanWidth = children.length * cardWidth * (1 - overlapFactor) + cardWidth * overlapFactor;
    
    // Scale down if needed
    final scale = idealFanWidth > availableWidth 
        ? math.max(minCardWidth / cardWidth, availableWidth / idealFanWidth)
        : 1.0;
    
    final scaledCardWidth = cardWidth * scale;
    final scaledCardHeight = cardHeight * scale;
    final scaledFanHeight = fanHeight * scale;
    
    // Calculate positions for each card
    final cardSpacing = scaledCardWidth * (1 - overlapFactor);
    final totalWidth = (children.length - 1) * cardSpacing + scaledCardWidth;
    
    return SizedBox(
      height: scaledFanHeight,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          final cardCount = children.length;
          
          // Calculate position and rotation for this card
          final progress = cardCount == 1 ? 0.5 : index / (cardCount - 1); // 0 to 1, center at 0.5
          final centerOffset = (progress - 0.5) * 2; // -1 to 1
          
          // Rotation angle
          final angle = centerOffset * maxAngle;
          
          // Horizontal position
          final x = index * cardSpacing;
          
          // Vertical position (slight arc effect)
          final arcHeight = math.sin(progress * math.pi) * 12 * scale;
          final y = scaledFanHeight - scaledCardHeight - arcHeight;
          
          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}