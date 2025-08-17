import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.playerName,
    this.size = 40,
    this.isYou = false,
  });

  final String? playerName;
  final double size;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    if (playerName == null) {
      // Empty seat
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.grey),
      );
    }

    final initials = _getInitials(playerName!);
    final color = _getStableColor(playerName!);
    
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (isYou)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    // Extract initials from names like "Alice#1001"
    final cleanName = name.split('#').first;
    final parts = cleanName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleanName.length >= 2 ? cleanName.substring(0, 2).toUpperCase() : cleanName.toUpperCase();
  }

  Color _getStableColor(String name) {
    // Generate stable color based on name hash
    final hash = name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}