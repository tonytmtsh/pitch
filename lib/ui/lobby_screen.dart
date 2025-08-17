import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pitch_service.dart';
import '../state/lobby_store.dart';
import '../state/settings_store.dart';
import 'table_screen.dart';
import 'widgets/help_dialog.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/lobby_table_card.dart';
import 'widgets/responsive_layout.dart';

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
    final isGridLayout = ResponsiveLayout.showGridLayout(context);

    final baseTitle = 'Pitch — Lobby (${backendLabel[0].toUpperCase()}${backendLabel.substring(1)})';
    final fullTitle = userLabel.isNotEmpty ? '$baseTitle $userLabel' : baseTitle;
    return Scaffold(
      appBar: AppBar(
        title: Text(fullTitle),
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
            _buildFiltersSection(context, store),
            _buildResultsCounter(store),
            Expanded(
              child: isGridLayout 
                  ? _buildGridLayout(context, store)
                  : _buildListLayout(context, store),
            ),
          ],
        );
      }(),
    );
  }

  Widget _buildFiltersSection(BuildContext context, LobbyStore store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search tables...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: store.setSearchText,
          ),
          const SizedBox(height: 12),
          // Filter dropdowns
          ResponsiveLayout.isMobile(context)
              ? Column(children: [
                  _buildFilterRow(store),
                  const SizedBox(height: 8),
                  _buildSortAndClearRow(store),
                ])
              : Row(children: [
                  ..._buildFilterRow(store),
                  const Spacer(),
                  ..._buildSortAndClearRow(store),
                ]),
        ],
      ),
    );
  }

  List<Widget> _buildFilterRow(LobbyStore store) {
    return [
      Expanded(
        child: DropdownButtonFormField<String>(
          value: store.variantFilter,
          decoration: const InputDecoration(
            labelText: 'Variant',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Variants')),
            DropdownMenuItem(value: '4_point', child: Text('4-Point')),
            DropdownMenuItem(value: '10_point', child: Text('10-Point')),
          ],
          onChanged: (value) => value != null ? store.setVariantFilter(value) : null,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: store.statusFilter,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'open', child: Text('Open')),
            DropdownMenuItem(value: 'playing', child: Text('Playing')),
          ],
          onChanged: (value) => value != null ? store.setStatusFilter(value) : null,
        ),
      ),
    ];
  }

  List<Widget> _buildSortAndClearRow(LobbyStore store) {
    return [
      DropdownButton<LobbySort>(
        value: store.sort,
        items: const [
          DropdownMenuItem(value: LobbySort.nameAsc, child: Text('Name A-Z')),
          DropdownMenuItem(value: LobbySort.nameDesc, child: Text('Name Z-A')),
          DropdownMenuItem(value: LobbySort.leastFull, child: Text('Least Full')),
          DropdownMenuItem(value: LobbySort.mostFull, child: Text('Most Full')),
          DropdownMenuItem(value: LobbySort.openFirst, child: Text('Open First')),
        ],
        onChanged: (value) => value != null ? store.setSort(value) : null,
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: store.clearFilters,
        icon: const Icon(Icons.clear),
        label: const Text('Clear'),
      ),
    ];
  }

  Widget _buildResultsCounter(LobbyStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Showing ${store.filteredTablesCount} of ${store.totalTables} tables',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, LobbyStore store) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: store.tables.length,
      itemBuilder: (ctx, i) => _buildTableCard(ctx, store.tables[i]),
    );
  }

  Widget _buildListLayout(BuildContext context, LobbyStore store) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: store.tables.length,
      itemBuilder: (ctx, i) => _buildTableCard(ctx, store.tables[i]),
    );
  }

  Widget _buildTableCard(BuildContext context, LobbyTable table) {
    final svc = context.read<PitchService>();
    final showQuickJoin = !svc.supportsIdentity(); // Mock only
    
    return LobbyTableCard(
      table: table,
      onTap: () async {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TableScreen(tableId: table.id, name: table.name),
        ));
      },
      onQuickJoin: showQuickJoin ? () async {
        final success = await svc.joinTable(table.id);
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joined ${table.name}!')),
            );
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TableScreen(tableId: table.id, name: table.name),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to join table')),
            );
          }
        }
      } : null,
    );
  }
}
