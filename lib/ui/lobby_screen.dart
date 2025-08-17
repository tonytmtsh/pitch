import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pitch_service.dart';
import '../state/lobby_store.dart';
import 'table_screen.dart';
import 'widgets/help_dialog.dart';

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
        return ListView.separated(
          itemCount: store.tables.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final t = store.tables[i];
            return ListTile(
              leading: Icon(
                  t.inProgress ? Icons.play_arrow : Icons.hourglass_empty),
              title: Text(t.name),
              subtitle: Text('Seats ${t.seatsTaken}/${t.seatsTotal}')
                  ,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.of(ctx).push(MaterialPageRoute(
                  builder: (_) => TableScreen(tableId: t.id, name: t.name),
                ));
              },
            );
          },
        );
      }(),
    );
  }
}
