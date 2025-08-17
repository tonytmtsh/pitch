import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fan/arc layout for a row of card widgets.
///
/// Calculates a horizontal arrangement with configurable overlap and rotates
/// each child slightly around the center, lifting the middle cards by [arcHeight].
class FanHand extends StatelessWidget {
  const FanHand.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardWidth = 64,
  this.overlapFraction = 0.35,
    this.maxAngleDeg = 10,
    this.arcHeight = 16,
  });

  final int itemCount;
  final Widget Function(int index, double effectiveCardWidth) itemBuilder;
  final double cardWidth;
  /// 0..1 fraction of how much adjacent cards overlap horizontally.
  final double overlapFraction;
  /// Maximum rotation at the edges (degrees). Center tends toward 0.
  final double maxAngleDeg;
  /// Vertical lift of the center card(s). Edge cards sit lower.
  final double arcHeight;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : cardWidth * itemCount;
        final clampedOverlap = overlapFraction.clamp(0.0, 0.95);
        final step = cardWidth * (1 - clampedOverlap);
        final needed = itemCount == 1 ? cardWidth : cardWidth + step * (itemCount - 1);
        final scale = needed > availableWidth && needed > 0 ? (availableWidth / needed) : 1.0;
        final effWidth = cardWidth * scale;
        final effStep = step * scale;
        final cardHeight = effWidth * 1.4;
        final totalWidth = itemCount == 1 ? effWidth : effWidth + effStep * (itemCount - 1);
        final leftPad = (availableWidth - totalWidth) / 2;

        // Height: cardHeight + arc lift (top space) + a little cushion
        final stackHeight = cardHeight + arcHeight + 8;

        return SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            // Note: children are added left-to-right; in a Stack, earlier
            // children paint first (behind). This yields the desired layering
            // where the left-most card is at the bottom and the right-most on top.
            children: List.generate(itemCount, (i) {
              // t in [-1, 1] across the row, center ~ 0.
              final t = itemCount == 1 ? 0.0 : (i / (itemCount - 1)) * 2 - 1;
              final angleDeg = _lerp(-maxAngleDeg, maxAngleDeg, (t + 1) / 2);
              final angleRad = angleDeg * math.pi / 180;
              // Parabolic vertical lift: center highest (negative y to move upward)
              final yLift = -arcHeight * (1 - (t * t));
              final x = leftPad + i * effStep;
              final y = (arcHeight) + yLift; // base offset so edges ~0 lift

              final child = itemBuilder(i, effWidth);
              return Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: angleRad,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
