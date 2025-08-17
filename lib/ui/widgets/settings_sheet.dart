import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/settings_store.dart';

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
                children: [
                  const Icon(Icons.settings),
                  const SizedBox(width: 8),
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show Legal Hints'),
                subtitle: const Text('Highlight playable cards'),
                value: settings.showHints,
                onChanged: settings.setShowHints,
              ),
              SwitchListTile(
                title: const Text('Sound Effects'),
                subtitle: const Text('Play sounds for actions'),
                value: settings.soundsEnabled,
                onChanged: settings.setSoundsEnabled,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Default Variant'),
                subtitle: DropdownButton<String>(
                  value: settings.defaultVariant,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '4_point', child: Text('4-Point')),
                    DropdownMenuItem(value: '10_point', child: Text('10-Point')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setDefaultVariant(value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}