import 'package:flutter/material.dart';

import 'models/sort_option.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.defaultSortOption,
    required this.onDefaultSortOptionChanged,
    required this.onClearCompleted,
    required this.onResetAll,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final SortOption defaultSortOption;
  final ValueChanged<SortOption> onDefaultSortOptionChanged;
  final VoidCallback onClearCompleted;
  final VoidCallback onResetAll;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) onThemeModeChanged(value);
            },
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(switch (mode) {
                      ThemeMode.system => 'System',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    }),
                    value: mode,
                  ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Default sort order'),
          RadioGroup<SortOption>(
            groupValue: defaultSortOption,
            onChanged: (value) {
              if (value != null) onDefaultSortOptionChanged(value);
            },
            child: Column(
              children: [
                for (final option in SortOption.values)
                  RadioListTile<SortOption>(
                    title: Text(option.label),
                    value: option,
                  ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: const Text('Clear completed tasks'),
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Clear completed tasks?',
                message:
                    'This removes every task marked done. This cannot be undone.',
                confirmLabel: 'Clear',
              );
              if (confirmed) onClearCompleted();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Reset all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final confirmed = await _confirm(
                context,
                title: 'Reset all data?',
                message:
                    'This permanently deletes every task. This cannot be undone.',
                confirmLabel: 'Delete everything',
              );
              if (confirmed) onResetAll();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
