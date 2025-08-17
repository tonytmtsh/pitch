import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ui/lobby_screen.dart';
import 'services/pitch_service.dart';
import 'services/mock_pitch_service.dart';
import 'services/supabase/supabase_pitch_service.dart';
import 'state/settings_store.dart';

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

    return MultiProvider(
      providers: [
        Provider<PitchService>(
          create: (_) {
            if (backend == 'server') {
              return SupabasePitchService(url: supabaseUrl, anonKey: supabaseAnon);
            }
            return MockPitchService();
          },
        ),
        ChangeNotifierProvider<SettingsStore>(
          create: (_) => SettingsStore(),
        ),
      ],
      child: MaterialApp(
        title: 'Pitch',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: Builder(builder: (ctx) {
          final svc = ctx.read<PitchService>();
          if (backend == 'server' && svc.supportsIdentity() && svc.currentUserId() == null) {
            return _SignInScreen(supabaseUrl: supabaseUrl, supabaseAnon: supabaseAnon);
          }
          return const LobbyScreen();
        }),
      ),
    );
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen({required this.supabaseUrl, required this.supabaseAnon});
  final String supabaseUrl;
  final String supabaseAnon;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pitch — Sign In')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not signed in.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // For demo: sign in anonymously
                if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) return;
                final client = Supabase.instance.client;
                await client.auth.signInAnonymously();
                (context as Element).markNeedsBuild();
              },
              child: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }
}
        // the command line to start the app).
