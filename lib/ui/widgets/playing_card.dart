import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple playing card renderer using a short code like 'AS', '10H', 'QC'.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.code,
    this.width = 56,
    this.faceUp = true,
    this.highlight = false,
    this.disabled = false,
  });

  final String code;
  final double width;
  final bool faceUp;
  final bool highlight;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final size = Size(width, width * 1.4);
    final radius = BorderRadius.circular(8);
    final (rank, suitChar) = _parse(code);
    final (suit, color) = _suitInfo(suitChar);
    final accessibleLabel = faceUp ? _accessibleLabel(rank, suitChar) : 'Face-down card';

    return Semantics(
      label: accessibleLabel,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: faceUp ? Colors.white : const Color(0xFF0D47A1),
            borderRadius: radius,
            border: Border.all(
              color: highlight ? Colors.teal : Colors.black26,
              width: highlight ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black12),
            ],
          ),
          child: faceUp
              ? _Face(rank: rank, suit: suit, color: color)
              : const _BackPattern(),
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

  /// Generate accessible label for screen readers
  String _accessibleLabel(String rank, String suitChar) {
    final rankName = _getRankName(rank);
    final suitName = _getSuitName(suitChar);
    
    if (rankName.isEmpty || suitName.isEmpty) {
      return 'Unknown card';
    }
    
    return '$rankName of $suitName';
  }

  String _getRankName(String rank) {
    switch (rank.toLowerCase()) {
      case 'a':
        return 'Ace';
      case '2':
        return 'Two';
      case '3':
        return 'Three';
      case '4':
        return 'Four';
      case '5':
        return 'Five';
      case '6':
        return 'Six';
      case '7':
        return 'Seven';
      case '8':
        return 'Eight';
      case '9':
        return 'Nine';
      case '10':
        return 'Ten';
      case 'j':
        return 'Jack';
      case 'q':
        return 'Queen';
      case 'k':
        return 'King';
      default:
        return '';
    }
  }

  String _getSuitName(String suit) {
    switch (suit.toLowerCase()) {
      case 'h':
        return 'Hearts';
      case 'd':
        return 'Diamonds';
      case 'c':
        return 'Clubs';
      case 's':
        return 'Spades';
      default:
        return '';
    }
  }
}

class CardButton extends StatefulWidget {
  const CardButton({
    super.key, 
    required this.child, 
    this.onTap, 
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });
  
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<CardButton> {
  double _scale = 1.0;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTap() async {
    if (!widget.enabled || widget.onTap == null) return;
    
    setState(() => _scale = 0.96);
    await Future.delayed(const Duration(milliseconds: 60));
    if (mounted) {
      setState(() => _scale = 1.0);
      widget.onTap!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 80),
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && 
              event.logicalKey == LogicalKeyboardKey.enter &&
              widget.enabled && 
              widget.onTap != null) {
            _handleTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: _focusNode,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: widget.enabled && widget.onTap != null ? _handleTap : null,
            child: widget.child,
          ),
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
