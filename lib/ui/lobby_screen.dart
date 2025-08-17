import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/mock_pitch_service.dart';
import '../services/pitch_service.dart';
import '../services/supabase/supabase_pitch_service.dart';
import '../state/lobby_store.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const supabaseAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    return Provider<PitchService>(
      create: (_) {
        if (backend == 'server') {
          // NOTE: Supabase client not wired yet; this stub prepares the URL/key.
          return SupabasePitchService(url: supabaseUrl, anonKey: supabaseAnon);
        }
        return MockPitchService();
      },
      child: ChangeNotifierProvider(
        create: (ctx) => LobbyStore(ctx.read<PitchService>())..refresh(),
    child: const _LobbyBody(backendLabel: backend),
      ),
    );
  }
}

class _LobbyBody extends StatelessWidget {
  const _LobbyBody({required this.backendLabel});

  final String backendLabel;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LobbyStore>();

    return Scaffold(
      appBar: AppBar(title: Text('Pitch — Lobby (${backendLabel[0].toUpperCase()}${backendLabel.substring(1)})')),
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
                // You can navigate to a table screen later; for now, snackbar.
                ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Open table ${t.name}')));
              },
            );
          },
        );
      }(),
    );
  }
}
