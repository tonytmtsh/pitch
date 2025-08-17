import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'pitch_service.dart';

class MockPitchService implements PitchService {
  @override
  Future<List<LobbyTable>> fetchLobby() async {
    final raw = await rootBundle.loadString('mock/lobby.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final tables = (jsonMap['tables'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) => LobbyTable.fromJson(e))
        .toList();
    return tables;
  }

  @override
  Future<TableDetails> fetchTable(String tableId) async {
    // For simplicity, a single representative table snapshot.
    final raw = await rootBundle.loadString('mock/table_10pt_full.json');
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    return TableDetails.fromJson(jsonMap);
  }
}
