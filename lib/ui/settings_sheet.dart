import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_store.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsStore>(
      builder: (context, settings, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show legal hints'),
                subtitle: const Text('Highlight playable cards'),
                value: settings.showHints,
                onChanged: settings.setShowHints,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Sounds'),
                subtitle: const Text('Enable game sounds'),
                value: settings.soundsEnabled,
                onChanged: settings.setSoundsEnabled,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Default variant'),
                subtitle: Text('New tables use ${settings.defaultVariant == '10_point' ? '10-point' : '4-point'} rules'),
                trailing: DropdownButton<String>(
                  value: settings.defaultVariant,
                  items: const [
                    DropdownMenuItem(value: '10_point', child: Text('10-point')),
                    DropdownMenuItem(value: '4_point', child: Text('4-point')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setDefaultVariant(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SettingsSheet(),
    );
  }
}