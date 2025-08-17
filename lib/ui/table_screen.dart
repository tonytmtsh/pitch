import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/playing_card.dart';
import 'theme/pitch_theme.dart';

import '../services/pitch_service.dart';
import '../state/table_store.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key, required this.tableId, required this.name});

  final String tableId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TableStore(ctx.read<PitchService>(), tableId)..refresh(),
      child: _TableBody(name: name),
    );
  }
}

class _TableBody extends StatelessWidget {
  const _TableBody({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TableStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
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
  return Container(
          decoration: PitchTheme.createFeltBackground(context),
          child: RefreshIndicator(
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
                  leading: CircleAvatar(child: Text(label)),
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
                return ListTile(
                  leading: CircleAvatar(child: Text(p)),
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
                      items: [
                        DropdownMenuItem(
                          value: 'S', 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(PitchTheme.getSuitSymbol('S'), 
                                style: TextStyle(color: PitchTheme.getSuitColor('S'))),
                              const SizedBox(width: 4),
                              const Text('Spades'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'H', 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(PitchTheme.getSuitSymbol('H'), 
                                style: TextStyle(color: PitchTheme.getSuitColor('H'))),
                              const SizedBox(width: 4),
                              const Text('Hearts'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'D', 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(PitchTheme.getSuitSymbol('D'), 
                                style: TextStyle(color: PitchTheme.getSuitColor('D'))),
                              const SizedBox(width: 4),
                              const Text('Diamonds'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'C', 
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(PitchTheme.getSuitSymbol('C'), 
                                style: TextStyle(color: PitchTheme.getSuitColor('C'))),
                              const SizedBox(width: 4),
                              const Text('Clubs'),
                            ],
                          ),
                        ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: store.myCards.map((c) {
                      final isLegal = legal.contains(c);
                      return CardButton(
                        enabled: isMyTurn && isLegal && (active?.id != null),
                        onTap: (isMyTurn && isLegal && active?.id != null)
                            ? () => ctx.read<PitchService>().playCard(active!.id!, c)
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
              _CurrentTrickPanel(),
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
                              .map((c) {
                                final suit = (() {
                                  final match = RegExp(r'^(?:[2-9]|10|[JQKA])([CDHS])$').firstMatch(c);
                                  return match != null ? match.group(1)! : '';
                                })();
                                return ElevatedButton(
                                  onPressed: active.id != null
                                      ? () => svc.playCard(active.id!, c)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    side: BorderSide(
                                      color: PitchTheme.getSuitColor(suit),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(c),
                                );
                              })
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
                title: Row(
                  children: [
                    const Text('Trumps: '),
                    Text(
                      PitchTheme.getSuitSymbol(store.scoring!.trumps),
                      style: TextStyle(
                        color: PitchTheme.getSuitColor(store.scoring!.trumps),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(store.scoring!.trumps),
                  ],
                ),
              ),
              ...store.scoring!.capturedBy.entries.map((e) {
                final suitGroups = _groupBySuit(e.value);
                final chips = suitGroups.entries
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 6),
                          child: PitchTheme.createSuitChip(
                            text: '${s.key}: ${s.value.join(' ')}',
                            suit: s.key,
                          ),
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
        ),
          ),
        );
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
