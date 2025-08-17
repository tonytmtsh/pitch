import 'package:flutter/foundation.dart';

import '../services/pitch_service.dart';

class LobbyStore extends ChangeNotifier {
  LobbyStore(this._service);

  final PitchService _service;

  List<LobbyTable> _tables = const [];
  bool _loading = false;
  Object? _error;

  List<LobbyTable> get tables => _tables;
  bool get loading => _loading;
  Object? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tables = await _service.fetchLobby();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
