import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:playing_cards/playing_cards.dart' as pc;
import 'card_slide_animation.dart';
import '../../services/sound_service.dart';
import '../../state/settings_store.dart';

/// Simple playing card renderer using a short code like 'AS', '10H', 'QC'.
class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.code,
    this.width = 56,
    this.faceUp = true,
    this.highlight = false,
    this.disabled = false,
  this.highlightColor,
  });

  final String code;
  final double width;
  final bool faceUp;
  final bool highlight;
  final bool disabled;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final size = Size(width, width * 1.4);
    final (rank, suitChar) = _parse(code);
    // Map code to playing_cards model
    final pcSuit = _toPcSuit(suitChar);
    final pcValue = _toPcValue(rank);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: highlight ? (highlightColor ?? Colors.amber) : Colors.black26,
        width: highlight ? 2 : 1,
      ),
    );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: pc.PlayingCardView(
        card: pc.PlayingCard(pcSuit, pcValue),
        showBack: !faceUp,
        elevation: 3.0,
        shape: shape,
      ),
    );
  }

  (String, String) _parse(String code) {
    if (code.isEmpty) return ('', '');
    final suit = code.substring(code.length - 1);
    final rank = code.substring(0, code.length - 1);
    return (rank, suit);
  }

  pc.Suit _toPcSuit(String s) {
    switch (s) {
      case 'H':
        return pc.Suit.hearts;
      case 'D':
        return pc.Suit.diamonds;
      case 'C':
        return pc.Suit.clubs;
      case 'S':
      default:
        return pc.Suit.spades;
    }
  }

  pc.CardValue _toPcValue(String r) {
    switch (r) {
      case 'A':
        return pc.CardValue.ace;
      case 'K':
        return pc.CardValue.king;
      case 'Q':
        return pc.CardValue.queen;
      case 'J':
        return pc.CardValue.jack;
      case '10':
        return pc.CardValue.ten;
      case '9':
        return pc.CardValue.nine;
      case '8':
        return pc.CardValue.eight;
      case '7':
        return pc.CardValue.seven;
      case '6':
        return pc.CardValue.six;
      case '5':
        return pc.CardValue.five;
      case '4':
        return pc.CardValue.four;
      case '3':
        return pc.CardValue.three;
      case '2':
      default:
        return pc.CardValue.two;
    }
  }

  // Using the package's default style so cards look like the demo
}

class CardButton extends StatefulWidget {
  const CardButton({
    super.key, 
    required this.child, 
    this.onTap, 
    this.enabled = true,
    this.cardCode,
    this.targetKey,
  });
  
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final String? cardCode;
  final GlobalKey? targetKey;

  @override
  State<CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<CardButton> {
  double _scale = 1.0;
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 80),
      child: Material(
        key: _cardKey,
        color: Colors.transparent,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: widget.enabled && widget.onTap != null
              ? () async {
                  // SettingsStore is optional in tests; guard lookup.
                  SettingsStore? settings;
                  try {
                    settings = context.read<SettingsStore>();
                  } catch (_) {
                    settings = null;
                  }

                  setState(() => _scale = 0.96);
                  await Future.delayed(const Duration(milliseconds: 60));
                  setState(() => _scale = 1.0);
                  
                  // Play sound if enabled
                  if (settings?.soundsEnabled == true) {
                    SoundService().playCardSound();
                  }
                  
                  // Play slide animation if we have the required parameters
                  if (widget.cardCode != null && widget.targetKey != null) {
                    await CardSlideAnimation.playCard(
                      context: context,
                      cardCode: widget.cardCode!,
                      sourceKey: _cardKey,
                      targetKey: widget.targetKey!,
                      onComplete: () {
                        widget.onTap!.call();
                      },
                    );
                  } else {
                    widget.onTap!.call();
                  }
                }
              : () async {
                  // Play invalid sound for disabled interactions (optional SettingsStore)
                  SettingsStore? settings;
                  try {
                    settings = context.read<SettingsStore>();
                  } catch (_) {
                    settings = null;
                  }
                  if (settings?.soundsEnabled == true) {
                    SoundService().playInvalidSound();
                  }
                },
          child: widget.child,
        ),
      ),
    );
  }
}

// Custom face/back removed in favor of playing_cards rendering
