import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pitch_service.dart';
import '../../state/table_store.dart';
import '../responsive.dart';

/// Bottom-aligned mobile controls for primary game actions
class MobileBottomControls extends StatefulWidget {
  const MobileBottomControls({super.key});

  @override
  State<MobileBottomControls> createState() => _MobileBottomControlsState();
}

class _MobileBottomControlsState extends State<MobileBottomControls> {
  double _bid = 4;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    
    // Don't show bottom controls on desktop
    if (!context.isMobile) {
      return const SizedBox.shrink();
    }

    // Show bidding controls during bidding phase
    if (store.bidding != null && !store.biddingActions.any((a) => a['pos'] == store.mySeatPos && a['pass'] == true)) {
      return _BiddingBottomControls(
        bid: _bid,
        onBidChanged: (value) => setState(() => _bid = value),
      );
    }

    // Show trump declaration controls if user won bidding
    if (store.mySeatPos == store.biddingWinnerPos && store.handState?.trump == null) {
      return const _TrumpDeclarationControls();
    }

    // Show replacement controls during replacement phase
    if (store.replacementsAll.isNotEmpty && !store.replacementsLocked) {
      return const _ReplacementBottomControls();
    }

    return const SizedBox.shrink();
  }
}

class _BiddingBottomControls extends StatelessWidget {
  const _BiddingBottomControls({
    required this.bid,
    required this.onBidChanged,
  });

  final double bid;
  final ValueChanged<double> onBidChanged;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (store.mySeatPos == null) ...[
              // Seat selection for mock mode
              Row(
                children: [
                  const Text('Choose seat:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: store.selectedBidPos,
                    items: store.biddingOrder
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) context.read<TableStore>().setSelectedBidPos(v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              store.isMyBidTurn 
                  ? "Your turn to bid" 
                  : "${store.nextBidPos}'s turn",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Bid: '),
                Expanded(
                  child: Slider(
                    value: bid,
                    min: 2,
                    max: 7,
                    divisions: 5,
                    label: bid.round().toString(),
                    onChanged: store.isMyBidTurn ? onBidChanged : null,
                  ),
                ),
                Text(bid.round().toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: store.isMyBidTurn
                        ? () => context.read<TableStore>().submitPass(store.selectedBidPos)
                        : null,
                    child: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: store.isMyBidTurn
                        ? () => context.read<TableStore>().submitBid(store.selectedBidPos, bid.round())
                        : null,
                    child: Text('Bid ${bid.round()}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrumpDeclarationControls extends StatelessWidget {
  const _TrumpDeclarationControls();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Declare Trump Suit',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TrumpButton(suit: 'S', label: '♠', color: Colors.black87),
                const SizedBox(width: 8),
                _TrumpButton(suit: 'H', label: '♥', color: Colors.red.shade700),
                const SizedBox(width: 8),
                _TrumpButton(suit: 'D', label: '♦', color: Colors.red.shade700),
                const SizedBox(width: 8),
                _TrumpButton(suit: 'C', label: '♣', color: Colors.black87),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrumpButton extends StatelessWidget {
  const _TrumpButton({
    required this.suit,
    required this.label,
    required this.color,
  });

  final String suit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          final handId = context.read<TableStore>().table?.handId;
          if (handId != null) {
            await context.read<PitchService>().declareTrump(handId, suit);
          }
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ReplacementBottomControls extends StatelessWidget {
  const _ReplacementBottomControls();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Replacement Phase',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your seat: ${store.mySeatPos ?? '-'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.read<TableStore>().lockReplacementsNow(),
                child: const Text('Lock Replacements'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}