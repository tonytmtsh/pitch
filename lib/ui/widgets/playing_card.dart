import 'package:flutter/material.dart';

/// Simple playing card renderer using a short code like 'AS', '10H', 'QC'.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.code,
    this.width = 56,
    this.faceUp = true,
    this.highlight = false,
    this.disabled = false,
    this.followsSuit = false,
  });

  final String code;
  final double width;
  final bool faceUp;
  final bool highlight;
  final bool disabled;
  final bool followsSuit;

  @override
  Widget build(BuildContext context) {
    final size = Size(width, width * 1.4);
    final radius = BorderRadius.circular(8);
    final (rank, suitChar) = _parse(code);
    final (suit, color) = _suitInfo(suitChar);

    // Determine border color and style based on state
    Color borderColor;
    double borderWidth;
    
    if (disabled) {
      borderColor = Colors.red.shade300;
      borderWidth = 1;
    } else if (followsSuit) {
      borderColor = Colors.green.shade600;
      borderWidth = 3;
    } else if (highlight) {
      borderColor = Colors.teal;
      borderWidth = 2;
    } else {
      borderColor = Colors.black26;
      borderWidth = 1;
    }

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: faceUp ? Colors.white : const Color(0xFF0D47A1),
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: const [
            BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black12),
          ],
        ),
        child: Stack(
          children: [
            if (faceUp)
              _Face(rank: rank, suit: suit, color: color)
            else
              const _BackPattern(),
            // Badge for following suit
            if (followsSuit && !disabled)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (String, String) _parse(String code) {
    if (code.isEmpty) return ('', '');
    final suit = code.substring(code.length - 1);
    final rank = code.substring(0, code.length - 1);
    return (rank, suit);
  }

  (String, Color) _suitInfo(String suit) {
    switch (suit) {
      case 'H':
        return ('♥', Colors.red.shade700);
      case 'D':
        return ('♦', Colors.red.shade700);
      case 'C':
        return ('♣', Colors.black87);
      case 'S':
        return ('♠', Colors.black87);
      default:
        return ('?', Colors.black54);
    }
  }
}

class CardButton extends StatefulWidget {
  const CardButton({super.key, required this.child, this.onTap, this.enabled = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<CardButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 80),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: widget.enabled && widget.onTap != null
              ? () async {
                  setState(() => _scale = 0.96);
                  await Future.delayed(const Duration(milliseconds: 60));
                  setState(() => _scale = 1.0);
                  widget.onTap!.call();
                }
              : null,
          child: widget.child,
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.rank, required this.suit, required this.color});
  final String rank;
  final String suit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = color;
    final rankStyle = TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16);
    final suitStyle = TextStyle(color: textColor, fontSize: 14);
    return Stack(
      children: [
        // Top-left
        Positioned(
          left: 6,
          top: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rank, style: rankStyle),
              Text(suit, style: suitStyle),
            ],
          ),
        ),
        // Bottom-right (rotated)
        Positioned(
          right: 6,
          bottom: 6,
          child: Transform.rotate(
            angle: 3.14159, // ~pi
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank, style: rankStyle),
                Text(suit, style: suitStyle),
              ],
            ),
          ),
        ),
        // Center suit glyph subtle
        Center(
          child: Opacity(
            opacity: 0.1,
            child: Text(
              suit,
              style: TextStyle(fontSize: 48, color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackPattern extends StatelessWidget {
  const _BackPattern();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.casino, color: Colors.white70),
      ),
    );
  }
}
