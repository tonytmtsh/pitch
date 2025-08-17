import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pitch_service.dart';
import '../../state/table_store.dart';
import 'playing_card.dart';
import '../responsive.dart';

/// Mobile-optimized hand widget with horizontal scrolling and compact cards
class MobileHandWidget extends StatelessWidget {
  const MobileHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    
    if (store.myCards.isEmpty) {
      return const SizedBox.shrink();
    }

    final legal = store.legalCardsForTurn().toSet();
    final tricks = store.tricksAll;
    final active = tricks.isNotEmpty ? tricks.last : null;
    final isMyTurn = store.currentTurnPos == store.mySeatPos;
    
    // Responsive card sizing
    final isMobile = context.isMobile;
    final cardWidth = isMobile ? 48.0 : 64.0;
    final spacing = isMobile ? 4.0 : 8.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('My Hand', style: TextStyle(fontWeight: FontWeight.w600)),
              if (isMyTurn) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your Turn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: isMobile ? 80 : 96, // Compact height on mobile
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: store.myCards.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (context, index) {
              final card = store.myCards[index];
              final isLegal = legal.contains(card);
              
              return CardButton(
                enabled: isMyTurn && isLegal && (active?.id != null),
                onTap: (isMyTurn && isLegal && active?.id != null)
                    ? () => context.read<PitchService>().playCard(active!.id!, card)
                    : null,
                child: PlayingCardView(
                  code: card,
                  width: cardWidth,
                  highlight: isMyTurn && isLegal,
                  disabled: !isLegal,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Desktop hand widget - uses wrap layout like the original
class DesktopHandWidget extends StatelessWidget {
  const DesktopHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    
    if (store.myCards.isEmpty) {
      return const SizedBox.shrink();
    }

    final legal = store.legalCardsForTurn().toSet();
    final tricks = store.tricksAll;
    final active = tricks.isNotEmpty ? tricks.last : null;
    final isMyTurn = store.currentTurnPos == store.mySeatPos;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('My Hand', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.myCards.map((c) {
              final isLegal = legal.contains(c);
              return CardButton(
                enabled: isMyTurn && isLegal && (active?.id != null),
                onTap: (isMyTurn && isLegal && active?.id != null)
                    ? () => context.read<PitchService>().playCard(active!.id!, c)
                    : null,
                child: PlayingCardView(
                  code: c,
                  width: 64,
                  highlight: isMyTurn && isLegal,
                  disabled: !isLegal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Responsive hand widget that switches between mobile and desktop layouts
class ResponsiveHandWidget extends StatelessWidget {
  const ResponsiveHandWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const MobileHandWidget(),
      desktop: const DesktopHandWidget(),
    );
  }
}