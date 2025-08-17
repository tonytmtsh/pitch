import 'package:flutter/material.dart';
import 'playing_card.dart';

/// Animation utility for sliding a card from source to target position
class CardSlideAnimation {
  static Future<void> playCard({
    required BuildContext context,
    required String cardCode,
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required VoidCallback onComplete,
    Duration duration = const Duration(milliseconds: 250),
  }) async {
    // Try to obtain an overlay; be resilient in test environments.
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    var completed = false;
    void completeOnce() {
      if (completed) return;
      completed = true;
      onComplete();
    }
    
    entry = OverlayEntry(
      builder: (context) => _CardSlideOverlay(
        cardCode: cardCode,
        sourceKey: sourceKey,
        targetKey: targetKey,
        duration: duration,
        onComplete: () {
          if (entry.mounted) entry.remove();
          completeOnce();
        },
      ),
    );
    
    // If no overlay is available, complete immediately
    if (overlay.mounted) {
      overlay.insert(entry);
  // Defensive: if animations fail to start/complete, force completion shortly after duration
  Future<void>.delayed(duration + const Duration(milliseconds: 20)).then((_) {
        if (!completed) {
          if (entry.mounted) entry.remove();
          completeOnce();
        }
      });
    } else {
      completeOnce();
    }
  }
}

class _CardSlideOverlay extends StatefulWidget {
  const _CardSlideOverlay({
    required this.cardCode,
    required this.sourceKey,
    required this.targetKey,
    required this.duration,
    required this.onComplete,
  });

  final String cardCode;
  final GlobalKey sourceKey;
  final GlobalKey targetKey;
  final Duration duration;
  final VoidCallback onComplete;

  @override
  State<_CardSlideOverlay> createState() => _CardSlideOverlayState();
}

class _CardSlideOverlayState extends State<_CardSlideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Offset? _sourcePosition;
  Offset? _targetPosition;
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Find source and target positions after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findPositions();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  void _findPositions() {
    try {
      // Get source position from GlobalKey
      final sourceContext = widget.sourceKey.currentContext;
      if (sourceContext != null) {
        final sourceBox = sourceContext.findRenderObject() as RenderBox?;
        if (sourceBox != null) {
          final sourcePosition = sourceBox.localToGlobal(Offset.zero);
          final sourceSize = sourceBox.size;
          _sourcePosition = Offset(
            sourcePosition.dx + sourceSize.width / 2,
            sourcePosition.dy + sourceSize.height / 2,
          );
        }
      }

      // Get target position from GlobalKey
      final targetContext = widget.targetKey.currentContext;
      if (targetContext != null) {
        final targetBox = targetContext.findRenderObject() as RenderBox?;
        if (targetBox != null) {
          final targetPosition = targetBox.localToGlobal(Offset.zero);
          final targetSize = targetBox.size;
          _targetPosition = Offset(
            targetPosition.dx + targetSize.width / 2,
            targetPosition.dy + targetSize.height / 2,
          );
        }
      }

      // Set up animations if we found both positions
      if (_sourcePosition != null && _targetPosition != null) {
        _setupAnimations();
        _controller.forward();
      } else {
        // Fallback: just complete immediately if we can't find positions
        widget.onComplete();
      }
    } catch (e) {
      // Fallback: complete immediately on any error
      widget.onComplete();
    }
  }

  void _setupAnimations() {
    final start = _sourcePosition!;
    final end = _targetPosition!;

    _slideAnimation = Tween<Offset>(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    setState(() {
      _animationsReady = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animationsReady) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _slideAnimation.value.dx - 32, // Center the card
          top: _slideAnimation.value.dy - 44,  // Center the card
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: PlayingCardView(
                code: widget.cardCode,
                width: 64,
                highlight: true,
              ),
            ),
          ),
        );
      },
    );
  }
}