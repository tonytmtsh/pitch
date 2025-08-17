import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardHandWidget extends StatefulWidget {
  const KeyboardHandWidget({
    super.key,
    required this.cards,
    required this.legal,
    required this.onCardSelected,
    this.enabled = true,
  });

  final List<String> cards;
  final List<String> legal;
  final Function(String) onCardSelected;
  final bool enabled;

  @override
  State<KeyboardHandWidget> createState() => _KeyboardHandWidgetState();
}

class _KeyboardHandWidgetState extends State<KeyboardHandWidget> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus if enabled
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: widget.enabled ? _handleKeyEvent : null,
      child: Semantics(
        label: 'Your hand: ${widget.cards.length} cards',
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              final isSelected = index == _selectedIndex;
              final isLegal = widget.legal.contains(card);
              
              return _buildCard(card, isSelected, isLegal, index);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String card, bool isSelected, bool isLegal, int index) {
    return Semantics(
      label: _getCardLabel(card),
      hint: isLegal ? 'Playable card' : 'Not playable',
      selected: isSelected,
      button: isLegal,
      onTap: isLegal ? () => widget.onCardSelected(card) : null,
      child: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: isLegal ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : isLegal 
                    ? Colors.green 
                    : Colors.grey,
            width: isSelected ? 3 : (isLegal ? 2 : 1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            _formatCardForDisplay(card),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLegal ? Colors.black : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _moveSelection(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _moveSelection(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _selectCurrentCard();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _moveSelection(int direction) {
    setState(() {
      _selectedIndex = (_selectedIndex + direction).clamp(0, widget.cards.length - 1);
    });
  }

  void _selectCurrentCard() {
    if (_selectedIndex >= 0 && _selectedIndex < widget.cards.length) {
      final card = widget.cards[_selectedIndex];
      if (widget.legal.contains(card)) {
        widget.onCardSelected(card);
      }
    }
  }

  String _getCardLabel(String card) {
    // Convert card codes like "AS" to "Ace of Spades"
    final rank = _getRankName(card.substring(0, card.length - 1));
    final suit = _getSuitName(card.substring(card.length - 1));
    return '$rank of $suit';
  }

  String _getRankName(String rank) {
    switch (rank) {
      case 'A': return 'Ace';
      case 'K': return 'King';
      case 'Q': return 'Queen';
      case 'J': return 'Jack';
      case '10': return 'Ten';
      case '9': return 'Nine';
      case '8': return 'Eight';
      case '7': return 'Seven';
      case '6': return 'Six';
      case '5': return 'Five';
      case '4': return 'Four';
      case '3': return 'Three';
      case '2': return 'Two';
      default: return rank;
    }
  }

  String _getSuitName(String suit) {
    switch (suit) {
      case 'S': return 'Spades';
      case 'H': return 'Hearts';
      case 'D': return 'Diamonds';
      case 'C': return 'Clubs';
      default: return suit;
    }
  }

  String _formatCardForDisplay(String card) {
    // Convert card codes to display format
    final rank = card.substring(0, card.length - 1);
    final suit = card.substring(card.length - 1);
    final suitSymbol = _getSuitSymbol(suit);
    return '$rank$suitSymbol';
  }

  String _getSuitSymbol(String suit) {
    switch (suit) {
      case 'S': return '♠';
      case 'H': return '♥';
      case 'D': return '♦';
      case 'C': return '♣';
      default: return suit;
    }
  }
}