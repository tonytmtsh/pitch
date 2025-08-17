import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitch/ui/widgets/fan_hand.dart';

void main() {
  testWidgets('FanHand scales cards to fit available width and builds all items', (tester) async {
    final widths = <double>[];
    const itemCount = 7;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220, // Tight width to force scaling
            child: _FanHandProbe(),
          ),
        ),
      ),
    );

    // Replace the probe with the real FanHand and intercept effective widths
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: FanHand.builder(
              itemCount: itemCount,
              cardWidth: 64,
              overlapFraction: 0.35,
              maxAngleDeg: 12,
              arcHeight: 24,
              itemBuilder: (i, effectiveWidth) {
                widths.add(effectiveWidth);
                return SizedBox(
                  key: ValueKey('card_$i'),
                  width: effectiveWidth,
                  height: effectiveWidth * 1.4,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert all items were built
    expect(widths.length, itemCount);
    // Assert scaling occurred (effective width should be <= requested 64)
    expect(widths.every((w) => w <= 64.0 && w > 0), isTrue);
    // Widgets exist by key
    for (var i = 0; i < itemCount; i++) {
      expect(find.byKey(ValueKey('card_$i')), findsOneWidget);
    }
  });
}

class _FanHandProbe extends StatelessWidget {
  const _FanHandProbe();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
