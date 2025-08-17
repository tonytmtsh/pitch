import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_store.dart';

/// Settings bottom sheet with sound toggle
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Sound toggle
            Consumer<SettingsStore>(
              builder: (context, settings, child) {
                return SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle: const Text('Card play, trick win, and error sounds'),
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    settings.setSoundEnabled(value);
                  },
                  secondary: Icon(
                    settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}