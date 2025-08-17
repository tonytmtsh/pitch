import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/lobby_screen.dart';
import 'services/pitch_service.dart';
import 'services/mock_pitch_service.dart';
import 'services/supabase/supabase_pitch_service.dart';

Future<void> main() async {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  WidgetsFlutterBinding.ensureInitialized();
  if (backend == 'server' && supabaseUrl.isNotEmpty && supabaseAnon.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const supabaseAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    return Provider<PitchService>(
      create: (_) {
        if (backend == 'server') {
          return SupabasePitchService(url: supabaseUrl, anonKey: supabaseAnon);
        }
        return MockPitchService();
      },
      child: MaterialApp(
        title: 'Pitch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const LobbyScreen(),
      ),
    );
  }
}
        // the command line to start the app).
