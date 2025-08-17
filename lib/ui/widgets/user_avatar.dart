import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility for creating user avatars with stable colors and initials
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40.0,
    this.fontSize = 16.0,
    this.isCurrentUser = false,
  });

  final String? name;
  final double size;
  final double fontSize;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    if (name == null || name!.isEmpty) {
      // Empty seat - show placeholder
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          Icons.person_outline,
          size: size * 0.6,
          color: Colors.grey.shade600,
        ),
      );
    }

    final initial = _getInitial(name!);
    final color = _getStableColor(name!);
    
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _getTextColor(color),
        ),
      ),
    );
  }

  /// Extract the first letter of the display name as initial
  String _getInitial(String name) {
    // Handle names like "Alice#1001" - take first letter of name part
    final namePart = name.split('#').first.trim();
    if (namePart.isEmpty) return '?';
    return namePart[0].toUpperCase();
  }

  /// Generate a stable color based on the name
  Color _getStableColor(String name) {
    // Use a predefined set of pleasant colors for avatars
    final colors = [
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.purple.shade400,
      Colors.deepPurple.shade400,
      Colors.indigo.shade400,
      Colors.blue.shade400,
      Colors.lightBlue.shade400,
      Colors.cyan.shade400,
      Colors.teal.shade400,
      Colors.green.shade400,
      Colors.lightGreen.shade400,
      Colors.lime.shade400,
      Colors.amber.shade400,
      Colors.orange.shade400,
      Colors.deepOrange.shade400,
      Colors.brown.shade400,
    ];

    // Generate stable hash from name to pick color consistently
    final hash = name.hashCode;
    final index = hash.abs() % colors.length;
    return colors[index];
  }

  /// Determine if text should be white or dark based on background color
  Color _getTextColor(Color backgroundColor) {
    // Calculate luminance to determine contrast
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Enhanced seat chip widget with "You" badge
class SeatChip extends StatelessWidget {
  const SeatChip({
    super.key,
    required this.position,
    required this.playerName,
    this.isCurrentUser = false,
    this.isOpen = false,
  });

  final String position; // N, E, S, W
  final String? playerName;
  final bool isCurrentUser;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            name: playerName,
            size: 32,
            fontSize: 14,
            isCurrentUser: isCurrentUser,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerName ?? 'Open',
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seat $position',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}