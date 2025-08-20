import 'package:flutter/material.dart';
import 'playing_card.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 800.0;
  static const double desktopBreakpoint = 1200.0;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool showGridLayout(BuildContext context) {
  return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
}

class MobileHandWidget extends StatelessWidget {
  const MobileHandWidget({
    super.key,
    required this.cards,
    required this.onCardTap,
    required this.legal,
  });

  final List<String> cards;
  final Function(String) onCardTap;
  final List<String> legal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final isLegal = legal.contains(card);
          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: CardButton(
              enabled: isLegal,
              onTap: isLegal ? () => onCardTap(card) : null,
              child: PlayingCardView(
                code: card,
                width: 56,
                highlight: isLegal,
                highlightColor: Colors.green,
                disabled: !isLegal,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MobileBottomControls extends StatelessWidget {
  const MobileBottomControls({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class MobileCurrentTrickPanel extends StatelessWidget {
  const MobileCurrentTrickPanel({
    super.key,
    required this.cards,
    required this.leader,
  });

  final List<Map<String, String>> cards;
  final String leader;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Current Trick (Leader: $leader)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: cards.map((card) {
                final code = card['card'];
                return code != null && code.isNotEmpty
                    ? AspectRatio(
                        aspectRatio: 56 / (56 * 1.4),
                        child: Center(
                          child: SizedBox(
                            width: 40,
                            child: PlayingCardView(code: code, width: 40),
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Center(
                          child: Text('—', style: TextStyle(fontSize: 10)),
                        ),
                      );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}