import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pitch_service.dart';
import '../state/lobby_store.dart';
import 'table_screen.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');
    final svc = context.read<PitchService>();
    final supportsId = svc.supportsIdentity();
    final uid = svc.currentUserId();
    return ChangeNotifierProvider(
      create: (ctx) => LobbyStore(ctx.read<PitchService>())..refresh(),
      child: _LobbyBody(
        backendLabel: backend,
        userLabel: supportsId && uid != null
            ? '— ${uid.substring(0, 8)}'
            : '',
        showSignOut: supportsId && uid != null,
      ),
    );
  }
}

class _LobbyBody extends StatelessWidget {
  const _LobbyBody({required this.backendLabel, required this.userLabel, required this.showSignOut});

  final String backendLabel;
  final String userLabel;
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LobbyStore>();

    final baseTitle = 'Pitch — Lobby (${backendLabel[0].toUpperCase()}${backendLabel.substring(1)})';
    final fullTitle = userLabel.isNotEmpty ? '$baseTitle $userLabel' : baseTitle;
    return Scaffold(
      appBar: AppBar(
        title: Text(fullTitle),
        actions: [
          if (showSignOut)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () async {
                await context.read<PitchService>().signOut();
                // Rebuild lobby to reflect signed-out state
                (context as Element).markNeedsBuild();
              },
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
        return Column(
          children: [
            // Search and Filter Controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search tables by name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) => store.setSearchText(text),
                  ),
                  const SizedBox(height: 12),
                  // Filter and Sort row
                  Row(
                    children: [
                      // Variant filter
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Variant',
                            border: OutlineInputBorder(),
                          ),
                          value: store.variantFilter,
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('All Variants')),
                            DropdownMenuItem<String?>(value: '4_point', child: Text('4-Point')),
                            DropdownMenuItem<String?>(value: '10_point', child: Text('10-Point')),
                          ],
                          onChanged: (value) => store.setVariantFilter(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status filter  
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          value: store.statusFilter,
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('All Status')),
                            DropdownMenuItem<String?>(value: 'open', child: Text('Open')),
                            DropdownMenuItem<String?>(value: 'playing', child: Text('Playing')),
                          ],
                          onChanged: (value) => store.setStatusFilter(value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sort dropdown
                      Expanded(
                        child: DropdownButtonFormField<LobbySort>(
                          decoration: const InputDecoration(
                            labelText: 'Sort',
                            border: OutlineInputBorder(),
                          ),
                          value: store.sortBy,
                          items: const [
                            DropdownMenuItem(value: LobbySort.nameAsc, child: Text('Name A-Z')),
                            DropdownMenuItem(value: LobbySort.nameDesc, child: Text('Name Z-A')),
                            DropdownMenuItem(value: LobbySort.occupancyAsc, child: Text('Least Full')),
                            DropdownMenuItem(value: LobbySort.occupancyDesc, child: Text('Most Full')),
                            DropdownMenuItem(value: LobbySort.statusOpen, child: Text('Open First')),
                          ],
                          onChanged: (value) => value != null ? store.setSortBy(value) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Clear filters button
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => store.clearFilters(),
                        child: const Text('Clear Filters'),
                      ),
                      const Spacer(),
                      Text('${store.tables.length} of ${store.allTables.length} tables'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Table list
            Expanded(
              child: ListView.separated(
                itemCount: store.tables.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final t = store.tables[i];
                  return ListTile(
                    leading: Icon(
                        t.inProgress ? Icons.play_arrow : Icons.hourglass_empty),
                    title: Text(t.name),
                    subtitle: Text('${t.variant == '4_point' ? '4-Point' : '10-Point'} • Seats ${t.seatsTaken}/${t.seatsTotal}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => TableScreen(tableId: t.id, name: t.name),
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        );
      }(),
    );
  }
}
