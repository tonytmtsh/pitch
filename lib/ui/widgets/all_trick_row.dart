import 'package:flutter/material.dart';
import 'playing_card.dart';

class AllTrickRow extends StatelessWidget {
  const AllTrickRow({
    super.key,
    required this.plays,
    required this.winner,
  });

  final List<Map<String, String>> plays; // [{pos, card}]
  final String winner; // seat letter

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < plays.length; i++) ...[
          _PlayCard(
            pos: plays[i]['pos']!,
            code: plays[i]['card']!,
            index: i + 1,
            isWinner: plays[i]['pos'] == winner,
            ordinal: _ordinal(i + 1),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({
    required this.pos,
    required this.code,
    required this.index,
    required this.isWinner,
    required this.ordinal,
  });

  final String pos;
  final String code;
  final int index;
  final bool isWinner;
  final String ordinal;

  @override
  Widget build(BuildContext context) {
    final badge = Positioned(
      left: -4,
      top: -4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '$index',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );

    final card = Container(
      decoration: BoxDecoration(
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PlayingCardView(code: code, width: 40, highlight: isWinner, highlightColor: Colors.amber),
          badge,
        ],
      ),
    );

    final tooltipText = 'Seat $pos: $code ($ordinal)${isWinner ? ' — winner' : ''}';

    return Semantics(
      label: 'Seat $pos played $code, $ordinal${isWinner ? ', winner' : ''}',
      child: Tooltip(
        message: tooltipText,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            card,
            const SizedBox(height: 4),
            Text(
              pos,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
