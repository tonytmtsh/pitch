import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pitch_service.dart';
import '../state/lobby_store.dart';
import 'table_screen.dart';
import 'widgets/lobby_table_card.dart';

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
        return _LobbyTableList(tables: store.tables);
      }(),
    );
  }
}

class _LobbyTableList extends StatelessWidget {
  const _LobbyTableList({required this.tables});

  final List<LobbyTable> tables;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        
        if (isWideScreen) {
          // Grid layout for larger screens
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              return _buildTableCard(context, tables[index]);
            },
          );
        } else {
          // List layout for smaller screens
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              return _buildTableCard(context, tables[index]);
            },
          );
        }
      },
    );
  }

  Widget _buildTableCard(BuildContext context, LobbyTable table) {
    final pitchService = context.read<PitchService>();
    final isMockService = !pitchService.supportsIdentity();
    
    return LobbyTableCard(
      table: table,
      onQuickJoin: isMockService ? () => _handleQuickJoin(context, table) : null,
    );
  }

  Future<void> _handleQuickJoin(BuildContext context, LobbyTable table) async {
    final pitchService = context.read<PitchService>();
    
    // For mock service, just show a snackbar and navigate to the table
    // In a real implementation, this would find an available seat and join
    const availablePositions = ['N', 'E', 'S', 'W'];
    final position = availablePositions.first; // For demo, just pick first
    
    try {
      final success = await pitchService.joinTable(table.id, position);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${table.name} at position $position'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TableScreen(tableId: table.id, name: table.name),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to join table'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining table: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
