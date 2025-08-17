import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/table_store.dart';
import 'playing_card.dart';
import '../responsive.dart';

/// Mobile-optimized current trick panel with compact card display
class MobileCurrentTrickPanel extends StatelessWidget {
  const MobileCurrentTrickPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    final t = store.currentTrick;
    if (t == null) return const SizedBox.shrink();
    
    final plays = {for (final p in t.plays) p['pos']!: p['card']!};
    final turnPos = store.currentTurnPos;
    final isMobile = context.isMobile;
    
    // Responsive card sizing
    final cardWidth = isMobile ? 40.0 : 56.0;

    Widget seat(String pos) {
      final card = plays[pos];
      final style = TextStyle(
        fontWeight: turnPos == pos ? FontWeight.bold : FontWeight.normal,
        color: turnPos == pos ? Colors.teal : null,
        fontSize: isMobile ? 12 : 14,
      );
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pos, style: style),
          SizedBox(height: isMobile ? 2 : 4),
          if (card != null)
            PlayingCardView(code: card, width: cardWidth)
          else
            Container(
              width: cardWidth,
              height: cardWidth * 1.4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('—'),
            ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 6 : 12,
      ),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            // Compact mobile layout - two rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                seat('W'),
                seat('N'),
                seat('E'),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: seat('S')),
          ] else ...[
            // Original desktop layout - diamond formation
            Center(child: seat('N')),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                seat('W'),
                seat('E'),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: seat('S')),
          ],
        ],
      ),
    );
  }
}

/// Responsive current trick panel that switches between mobile and desktop layouts
class ResponsiveCurrentTrickPanel extends StatelessWidget {
  const ResponsiveCurrentTrickPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const MobileCurrentTrickPanel(),
      desktop: const DesktopCurrentTrickPanel(),
    );
  }
}

/// Desktop current trick panel - maintains original layout
class DesktopCurrentTrickPanel extends StatelessWidget {
  const DesktopCurrentTrickPanel();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    final t = store.currentTrick;
    if (t == null) return const SizedBox.shrink();
    
    final plays = {for (final p in t.plays) p['pos']!: p['card']!};
    final turnPos = store.currentTurnPos;

    Widget seat(String pos) {
      final card = plays[pos];
      final style = TextStyle(
        fontWeight: turnPos == pos ? FontWeight.bold : FontWeight.normal,
        color: turnPos == pos ? Colors.teal : null,
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pos, style: style),
          const SizedBox(height: 4),
          if (card != null)
            PlayingCardView(code: card, width: 56)
          else
            Container(
              width: 56,
              height: 56 * 1.4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('—'),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Center(child: seat('N')),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              seat('W'),
              seat('E'),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: seat('S')),
        ],
      ),
    );
  }
}