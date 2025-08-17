import 'dart:async';

import '../pitch_service.dart';

/// Stub service to call Supabase RPCs and tables.
/// Fill in with supabase_flutter or postgrest once wiring begins.
class SupabasePitchService implements PitchService {
  SupabasePitchService({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  // TODO: set up Supabase client once dependency is added.
  // late final SupabaseClient _client = SupabaseClient(url, anonKey);

  @override
  Future<List<LobbyTable>> fetchLobby() async {
    // TODO: replace with REST/RPC call. For now, example transformation.
    // final res = await _client.from('tables').select('id,name,variant,status,table_seats(count)').eq('status','open');
    // Convert rows to LobbyTable
    return const <LobbyTable>[];
  }

  @override
  Future<TableDetails> fetchTable(String tableId) async {
    // TODO: call a view or RPC to return a table snapshot with seats.
    // Consider shape matching TableSnapshotDto; map to TableDetails.
    throw UnimplementedError('fetchTable not implemented');
  }
}
