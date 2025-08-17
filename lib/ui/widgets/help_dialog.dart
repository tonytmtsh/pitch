import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        child: SizedBox(
          width: 600,
          height: 700,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Pitch Rules & Variants'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close help dialog',
              ),
            ),
            body: Semantics(
              label: 'Game rules and variant differences',
              child: const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _HelpContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic rules section
        _SectionHeader('Basic Rules'),
        const SizedBox(height: 8),
        _RuleText('• 4 players in fixed partnerships (North-South vs East-West)'),
        _RuleText('• Standard trick-taking: follow suit if able, otherwise any card'),
        _RuleText('• Highest trump wins trick; if no trump, highest card of suit led wins'),
        _RuleText('• 52-card deck, rank high-to-low: A K Q J 10 9 8 7 6 5 4 3 2'),
        
        const SizedBox(height: 24),
        
        // Variant comparison section
        _SectionHeader('Variant Differences'),
        const SizedBox(height: 16),
        
        // 4-Point Pitch
        _VariantCard(
          title: '4-Point Pitch (Setback)',
          color: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          children: [
            _RuleText('• Deal: 6 cards each (3-and-3)'),
            _RuleText('• Minimum bid: 2'),
            _RuleText('• Target score: 11 points'),
            _RuleText('• No replacement phase'),
            const SizedBox(height: 8),
            _SubsectionHeader('Scoring (4 points per hand):'),
            _RuleText('  • High: 1 pt for highest trump played'),
            _RuleText('  • Low: 1 pt for lowest trump played'),
            _RuleText('  • Jack: 1 pt for Jack of trump (if played)'),
            _RuleText('  • Game: 1 pt for most game points'),
            const SizedBox(height: 8),
            _SubsectionHeader('Game card values:'),
            _RuleText('  • Ace = 4, King = 3, Queen = 2, Jack = 1, Ten = 10'),
            _RuleText('  • All other cards = 0'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 10-Point Pitch
        _VariantCard(
          title: '10-Point Pitch',
          color: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          children: [
            _RuleText('• Deal: 6 cards each (3-and-3)'),
            _RuleText('• Minimum bid: 3'),
            _RuleText('• Target score: 50 points (must bid to win)'),
            _RuleText('• Replacement phase: after bidding, players may discard 0-6 cards'),
            const SizedBox(height: 8),
            _SubsectionHeader('Scoring (up to 10 points per hand):'),
            _RuleText('  • High: 1 pt for highest trump played'),
            _RuleText('  • Low: 1 pt for lowest trump played'),
            _RuleText('  • Jack: 1 pt for Jack of trump (if played)'),
            _RuleText('  • Game: 1 pt for most game points'),
            _RuleText('  • Last Trick: 1 pt for winning last trick'),
            _RuleText('  • Five: 5 pts for Five of trump (if played)'),
            const SizedBox(height: 8),
            _SubsectionHeader('Game card values:'),
            _RuleText('  • Ten = 10, King = 3, Queen = 2, Jack = 1'),
            _RuleText('  • All other cards = 0'),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Bidding section
        _SectionHeader('Bidding & Play'),
        const SizedBox(height: 8),
        _RuleText('• Bidding starts left of dealer, one round'),
        _RuleText('• Highest bidder declares trump and leads first trick'),
        _RuleText('• If all pass, redeal by next dealer'),
        _RuleText('• Bidding team must make their bid or face setback (lose bid points)'),
        
        const SizedBox(height: 24),
        
        // External reference section
        _SectionHeader('External References'),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          hint: 'Tap to copy README link to clipboard',
          child: InkWell(
            onTap: () {
              // Copy link to clipboard since we can't open browser in modal context
              Clipboard.setData(const ClipboardData(text: 'https://github.com/tonytmtsh/pitch/blob/main/README.md'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('README link copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.open_in_new, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Full documentation and setup guide (tap to copy link)',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _RuleText extends StatelessWidget {
  const _RuleText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.title,
    required this.children,
    required this.color,
    required this.borderColor,
  });

  final String title;
  final List<Widget> children;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}