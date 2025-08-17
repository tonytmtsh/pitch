import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/playing_card.dart';
import 'widgets/help_dialog.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/user_avatar.dart';
// import 'widgets/responsive_layout.dart';
// import 'widgets/keyboard_hand_widget.dart';
import 'widgets/fan_hand.dart';

import '../services/pitch_service.dart';
import '../services/sound_service.dart';
import '../state/table_store.dart';
import '../state/settings_store.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key, required this.tableId, required this.name});

  final String tableId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        SettingsStore? settings;
        try {
          settings = ctx.read<SettingsStore>();
        } catch (_) {
          settings = null;
        }
        return TableStore(
          ctx.read<PitchService>(), 
          tableId,
          onTrickWin: () {
            if (settings?.soundsEnabled == true) {
              SoundService().playTrickWinSound();
            }
          },
        )..refresh();
      },
      child: _TableBody(name: name),
    );
  }
}

class _TableBody extends StatefulWidget {
  const _TableBody({required this.name});
  final String name;

  @override
  State<_TableBody> createState() => _TableBodyState();
}

class _TableBodyState extends State<_TableBody> {
  // Create GlobalKeys for each seat position for animation targeting
  final GlobalKey _northKey = GlobalKey();
  final GlobalKey _eastKey = GlobalKey();
  final GlobalKey _southKey = GlobalKey();
  final GlobalKey _westKey = GlobalKey();

  GlobalKey? _getTargetKeyForSeat(String? seatPos) {
    switch (seatPos) {
      case 'N': return _northKey;
      case 'E': return _eastKey;
      case 'S': return _southKey;
      case 'W': return _westKey;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const SettingsSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Rules & Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const HelpDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<TableStore>().refresh(),
          ),
        ],
      ),
      body: () {
        if (store.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (store.error != null) {
          return Center(
            child: Text('Error: ${store.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        final table = store.table;
        if (table == null) {
          return const SizedBox.shrink();
        }
  final pos = ['N', 'E', 'S', 'W'];
  final myId = context.read<PitchService>().currentUserId();
  return RefreshIndicator(
          onRefresh: () => context.read<TableStore>().refresh(),
          child: ListView(
          children: [
            const ListTile(title: Text('Seats')),
            const Divider(height: 1),
            ...table.seats.map((seat) {
              final label = pos[seat.position];
              final isMe = myId != null && seat.userId == myId;
              return Column(children: [
                ListTile(
                  leading: UserAvatar(
                    playerName: seat.player,
                    isYou: isMe,
                  ),
                  title: Text(
                    seat.player != null
                        ? isMe
                            ? '${seat.player} (You)'
                            : seat.player!
                        : 'Open',
                  ),
                  subtitle: Text('Seat $label'),
                ),
                const Divider(height: 1),
              ]);
            }),
            // Bidding section (mock snapshot)
            if (store.bidding != null) ...[
              const SizedBox(height: 8),
              const ListTile(title: Text('Bidding')),
              const Divider(height: 1),
              // Existing actions
              ...store.biddingActions.map((a) {
                final p = a['pos'] as String? ?? '?';
                final b = a['bid'];
                final pass = a['pass'] == true;
                final text = pass ? 'Pass' : 'Bid $b';
                final playerName = store.getPlayerNameByPosition(p);
                final isMyPosition = store.mySeatPos == p;
                return ListTile(
                  leading: UserAvatar(
                    playerName: playerName,
                    isYou: isMyPosition,
                    size: 30,
                  ),
                  title: Text(text),
                );
              }),
              // Simple input controls (gated by turn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    if (store.mySeatPos == null) ...[
                      const Text('Seat:'),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: store.selectedBidPos,
                        items: store.biddingOrder
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) context.read<TableStore>().setSelectedBidPos(v);
                        },
                      ),
                      const Spacer(),
                    ] else ...[
                      Text('Your seat: ${store.mySeatPos}')
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: store.isMyBidTurn
                          ? () => context.read<TableStore>().submitPass(store.selectedBidPos)
                          : null,
                      child: const Text('Pass'),
                    ),
                  ],
                ),
              ),
              _BidRow(),
              ListTile(
                title: Text('Winner: ${store.biddingWinnerPos}'),
                subtitle: Text('Bid ${store.biddingWinnerBid}'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Text('Declare trump:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: null,
                      hint: const Text('Suit'),
                      items: const [
                        DropdownMenuItem(value: 'S', child: Text('Spades')),
                        DropdownMenuItem(value: 'H', child: Text('Hearts')),
                        DropdownMenuItem(value: 'D', child: Text('Diamonds')),
                        DropdownMenuItem(value: 'C', child: Text('Clubs')),
                      ],
                      onChanged: store.mySeatPos == store.biddingWinnerPos
                          ? (suit) async {
                              if (suit == null) return;
                              final handId = context.read<TableStore>().table?.handId;
                              if (handId != null) {
                                await context.read<PitchService>().declareTrump(handId, suit);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            // My Hand (server mode shows your cards; mock shows placeholder)
            if (store.myCards.isNotEmpty) ...[
              const SizedBox(height: 8),
              const ListTile(title: Text('My Hand')),
              const Divider(height: 1),
              Builder(builder: (ctx) {
                final legal = store.legalCardsForTurn().toSet();
                final tricks = store.tricksAll;
                final active = tricks.isNotEmpty ? tricks.last : null;
                final isMyTurn = store.currentTurnPos == store.mySeatPos;
                final targetKey = _getTargetKeyForSeat(store.mySeatPos);
                final cards = store.myCardsSorted; // sorted/grouped view of hand
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FanHand.builder(
                    itemCount: cards.length,
                    cardWidth: 64,
                    maxAngleDeg: 12,
                    overlapFraction: 0.5, // closer together
                    arcHeight: 24,
                    itemBuilder: (i, effectiveWidth) {
                      final c = cards[i];
                      final isLegal = legal.contains(c);
                      final enabled = isMyTurn && isLegal && (active?.id != null);
                      return CardButton(
                        enabled: enabled,
                        cardCode: c,
                        targetKey: targetKey,
                        onTap: enabled ? () => ctx.read<PitchService>().playCard(active!.id!, c) : null,
                        child: PlayingCardView(
                          code: c,
                          width: effectiveWidth,
                          highlight: isMyTurn && isLegal,
                          highlightColor: Colors.amber,
                          disabled: !isLegal,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
            // Replacements section
            if (store.replacementsAll.isNotEmpty) ...[
              const SizedBox(height: 8),
              const ListTile(title: Text('Replacements')),
              const Divider(height: 1),
              if (!store.replacementsLocked)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text('Your seat: ${store.mySeatPos ?? '-'}'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => context.read<TableStore>().lockReplacementsNow(),
                        child: const Text('Lock Replacements'),
                      ),
                    ],
                  ),
                ),
              ...store.replacementsAll.map((r) => ListTile(
                    leading: CircleAvatar(child: Text(r.pos)),
                    title: Text('Discarded: ${r.discarded.join(', ')}'),
                    subtitle: Text('Drawn: ${r.drawn.join(', ')}'),
                  )),
              if (!store.replacementsLocked) _ReplacementInput(),
              const Divider(height: 1),
            ],
            // Tricks section
            if (store.tricksAll.isNotEmpty) ...[
              const SizedBox(height: 8),
              const ListTile(title: Text('Current Trick')),
              const Divider(height: 1),
              _CurrentTrickPanel(
                northKey: _northKey,
                eastKey: _eastKey,
                southKey: _southKey,
                westKey: _westKey,
              ),
              const SizedBox(height: 8),
              const ListTile(title: Text('All Tricks')),
              const Divider(height: 1),
              ...store.tricksAll.map((t) => ExpansionTile(
                    title: Text('Trick ${t.index + 1} — Winner ${t.winner}${t.lastTrick ? ' (Last Trick)' : ''}'),
                    subtitle: Text('Leader ${t.leader}'),
                    children: t.plays
                        .map((p) => ListTile(
                              leading: CircleAvatar(child: Text(p['pos']!)),
                              title: Text(p['card']!),
                            ))
                        .toList(),
                  )),
              // Minimal play control for the active trick when it's your turn (server mode)
              Builder(builder: (ctx) {
                final svc = ctx.read<PitchService>();
                final myPos = store.mySeatPos;
                if (myPos == null) return const SizedBox.shrink();
                final tricks = store.tricksAll;
                if (tricks.isEmpty) return const SizedBox.shrink();
                final active = tricks.last;
                // Determine whose turn it would be based on leader + current plays count
                final order = const ['N', 'E', 'S', 'W'];
                final leadIdx = order.indexOf(active.leader);
                final turnIdx = (leadIdx + active.plays.length) % 4;
                final turnPos = order[turnIdx];
                final isMyTurn = myPos == turnPos;
                final legal = store.legalCardsForTurn();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Play ($turnPos's turn)"),
                      const SizedBox(height: 8),
                      if (isMyTurn)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: legal
                              .map((c) => ElevatedButton(
                                    onPressed: active.id != null
                                        ? () => svc.playCard(active.id!, c)
                                        : null,
                                    child: Text(c),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                );
              }),
              // Hide mock trick input in server mode
              Builder(builder: (ctx) {
                final backend = const String.fromEnvironment('BACKEND', defaultValue: 'mock');
                if (backend == 'server') return const SizedBox.shrink();
                return _TrickInput();
              }),
            ],
            if (store.scoring != null) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Scoring'),
                trailing: DropdownButton<String>(
                  value: store.variant,
                  items: const [
                    DropdownMenuItem(value: '10_point', child: Text('10-point')),
                    DropdownMenuItem(value: '4_point', child: Text('4-point')),
                  ],
                  onChanged: (v) => v != null ? context.read<TableStore>().setVariant(v) : null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text('Trumps: ${store.scoring!.trumps}'),
              ),
              ...store.scoring!.capturedBy.entries.map((e) {
                final suitGroups = _groupBySuit(e.value);
                final chips = suitGroups.entries
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: Chip(label: Text('${s.key}: ${s.value.join(' ')}')),
                        ))
                    .toList();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key} captured'),
                      const SizedBox(height: 6),
                      Wrap(children: chips),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: store.scoring!.awards.entries
                      .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                      .toList(),
                ),
              ),
              ListTile(
                title: Text('Delta: NS ${store.scoring!.delta['NS'] ?? 0}, EW ${store.scoring!.delta['EW'] ?? 0}'),
                subtitle: Text('Game values: NS ${store.scoring!.gameValues['NS'] ?? 0}, EW ${store.scoring!.gameValues['EW'] ?? 0}'),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 16),
          ],
        ));
      }(),
    );
  }
}

class _BidRow extends StatefulWidget {
  @override
  State<_BidRow> createState() => _BidRowState();
}

class _ReplacementInput extends StatefulWidget {
  @override
  State<_ReplacementInput> createState() => _ReplacementInputState();
}

class _ReplacementInputState extends State<_ReplacementInput> {
  String _pos = 'N';
  final _discardCtrl = TextEditingController();
  final _drawnCtrl = TextEditingController();

  @override
  void dispose() {
    _discardCtrl.dispose();
    _drawnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add replacement'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _pos,
                items: const ['N', 'E', 'S', 'W']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pos = v ?? 'N'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final disc = _discardCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final drawn = _drawnCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  context.read<TableStore>().addReplacement(_pos, disc, drawn);
                  _discardCtrl.clear();
                  _drawnCtrl.clear();
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discardCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Discarded (comma-separated)'
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _drawnCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Drawn (comma-separated)'
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrickInput extends StatefulWidget {
  @override
  State<_TrickInput> createState() => _TrickInputState();
}

class _TrickInputState extends State<_TrickInput> {
  String _leader = 'N';
  final _cards = List.generate(4, (_) => TextEditingController());
  final _posOrder = const ['N', 'E', 'S', 'W'];

  @override
  void dispose() {
    for (final c in _cards) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add trick'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _leader,
                items: _posOrder
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _leader = v ?? 'N'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final plays = <Map<String, String>>[];
                  for (int i = 0; i < 4; i++) {
                    final card = _cards[i].text.trim();
                    if (card.isEmpty) continue;
                    final pos = _posOrder[(i + _posOrder.indexOf(_leader)) % 4];
                    plays.add({'pos': pos, 'card': card});
                  }
                  final winner = plays.isNotEmpty ? plays.first['pos']! : _leader;
                  context.read<TableStore>().addTrick(
                        leader: _leader,
                        plays: plays,
                        winner: winner,
                      );
                  for (final c in _cards) {
                    c.clear();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(4, (i) {
              final pos = _posOrder[(i + _posOrder.indexOf(_leader)) % 4];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text(pos)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cards[i],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Card (e.g., AS, 10H, QC)'
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

Map<String, List<String>> _groupBySuit(List<String> cards) {
  final map = <String, List<String>>{};
  for (final c in cards) {
    if (c.isEmpty) continue;
    final suit = c.characters.last;
    (map[suit] ??= <String>[]).add(c);
  }
  return map;
}

class _CurrentTrickPanel extends StatelessWidget {
  const _CurrentTrickPanel({
    required this.northKey,
    required this.eastKey,
    required this.southKey,
    required this.westKey,
  });

  final GlobalKey northKey;
  final GlobalKey eastKey;
  final GlobalKey southKey;
  final GlobalKey westKey;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    final t = store.currentTrick;
    
    // Show win reveal animation if one is active
    if (store.showingTrickWinReveal) {
      return GestureDetector(
        onTap: () => store.dismissTrickWinReveal(),
        child: const _TrickWinReveal(),
      );
    }
    
    if (t == null) return const SizedBox.shrink();
  final plays = {for (final p in t.plays) p['pos']!: p['card']!};
    final turnPos = store.currentTurnPos;

    Widget seat(String pos, GlobalKey key) {
      final card = plays[pos];
      final style = TextStyle(
        fontWeight: turnPos == pos ? FontWeight.bold : FontWeight.normal,
        color: turnPos == pos ? Colors.teal : null,
      );
      return Column(
        key: key,
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
          Center(child: seat('N', northKey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              seat('W', westKey),
              seat('E', eastKey),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: seat('S', southKey)),
        ],
      ),
    );
  }
}

class _BidRowState extends State<_BidRow> {
  double _bid = 4; // simple default

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
      Text('Bid (${store.nextBidPos}\'s turn)'),
          Expanded(
            child: Slider(
              value: _bid,
              min: 2,
              max: 7,
              divisions: 5,
              label: _bid.round().toString(),
              onChanged: (v) => setState(() => _bid = v),
            ),
          ),
          ElevatedButton(
      onPressed: store.isMyBidTurn
        ? () => context
          .read<TableStore>()
          .submitBid(store.selectedBidPos, _bid.round())
        : null,
            child: const Text('Bid'),
          ),
        ],
      ),
    );
  }
}

class _TrickWinReveal extends StatefulWidget {
  const _TrickWinReveal();

  @override
  State<_TrickWinReveal> createState() => _TrickWinRevealState();
}

class _TrickWinRevealState extends State<_TrickWinReveal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bannerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bannerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for winning card
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Banner slide-in animation
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bannerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _bannerController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    final trickSnapshot = store.trickWinRevealSnapshot;
    
    if (trickSnapshot == null) {
      return const SizedBox.shrink();
    }

    final plays = {for (final p in trickSnapshot.plays) p['pos']!: p['card']!};
    final winner = trickSnapshot.winner;
    final trickNumber = trickSnapshot.index + 1;

    Widget seatWithWinAnimation(String pos) {
      final card = plays[pos];
      final isWinner = pos == winner;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pos,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isWinner ? Colors.amber.shade700 : null,
            ),
          ),
          const SizedBox(height: 4),
          if (card != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isWinner ? _pulseAnimation.value : 1.0,
                  child: Container(
                    decoration: isWinner
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: PlayingCardView(
                      code: card,
                      width: 56,
                      highlight: isWinner,
                    ),
                  ),
                );
              },
            )
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

    return Stack(
      children: [
        // Card layout with win animation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Center(child: seatWithWinAnimation('N')),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  seatWithWinAnimation('W'),
                  seatWithWinAnimation('E'),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: seatWithWinAnimation('S')),
            ],
          ),
        ),
        // Win banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _bannerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -30 * (1 - _bannerAnimation.value)),
                child: Opacity(
                  opacity: _bannerAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trick $trickNumber won by $winner',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Next leader indicator
        if (trickNumber < 6) // Show only if not the last trick
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bannerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _bannerAnimation.value)),
                  child: Opacity(
                    opacity: _bannerAnimation.value * 0.8,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Next leader: $winner',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
