import 'package:flutter/material.dart';

/// Theme utilities for the Pitch game app.
class PitchTheme {
  /// Gets the color for a suit character (H, D, C, S).
  static Color getSuitColor(String suit) {
    switch (suit) {
      case 'H':
      case 'D':
        return Colors.red.shade700;
      case 'C':
      case 'S':
        return Colors.black87;
      default:
        return Colors.black54;
    }
  }

  /// Gets the suit symbol for a suit character.
  static String getSuitSymbol(String suit) {
    switch (suit) {
      case 'H':
        return '♥';
      case 'D':
        return '♦';
      case 'C':
        return '♣';
      case 'S':
        return '♠';
      default:
        return '?';
    }
  }

  /// Creates a subtle felt-like background decoration for the table.
  static BoxDecoration createFeltBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      // Dark mode: Deep green with subtle texture
      return BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF1B5E20), // Dark green center
            const Color(0xFF0D4713), // Darker green edges
          ],
        ),
      );
    } else {
      // Light mode: Traditional felt green
      return BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF2E7D32), // Medium green center
            const Color(0xFF1B5E20), // Darker green edges
          ],
        ),
      );
    }
  }

  /// Creates a card panel with suit-colored accent.
  static Widget createSuitAccentedPanel({
    required Widget child,
    String? suit,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: suit != null
            ? Border(
                left: BorderSide(
                  color: getSuitColor(suit),
                  width: 4,
                ),
              )
            : null,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: child,
    );
  }

  /// Creates a suit-colored chip for displaying cards or suits.
  static Widget createSuitChip({
    required String text,
    String? suit,
    VoidCallback? onTap,
  }) {
    final color = suit != null ? getSuitColor(suit) : null;
    
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          color: color != null ? Colors.white : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color?.withOpacity(0.8),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}