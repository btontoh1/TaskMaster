import 'package:flutter/material.dart';

import 'models/sort_option.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.defaultSortOption,
    required this.onDefaultSortOptionChanged,
    required this.reminderMinutes,
    required this.onReminderMinutesChanged,
    required this.onRequestNotificationPermission,
    required this.onClearCompleted,
    required this.onResetAll,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final SortOption defaultSortOption;
  final ValueChanged<SortOption> onDefaultSortOptionChanged;
  final int reminderMinutes;
  final ValueChanged<int> onReminderMinutesChanged;
  final VoidCallback onRequestNotificationPermission;
  final VoidCallback onClearCompleted;
  final VoidCallback onResetAll;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _themeMode;
  late SortOption _sortOption;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _sortOption = widget.defaultSortOption;
    _reminderMinutes = widget.reminderMinutes;
  }

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
            groupValue: _themeMode,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _themeMode = value);
              widget.onThemeModeChanged(value);
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
            groupValue: _sortOption,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _sortOption = value);
              widget.onDefaultSortOptionChanged(value);
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
          const _SectionHeader('Reminders'),
          RadioGroup<int>(
            groupValue: _reminderMinutes,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reminderMinutes = value);
              widget.onReminderMinutesChanged(value);
            },
            child: Column(
              children: [
                RadioListTile<int>(title: const Text('Off'), value: 0),
                RadioListTile<int>(
                  title: const Text('15 minutes before'),
                  value: 15,
                ),
                RadioListTile<int>(
                  title: const Text('30 minutes before'),
                  value: 30,
                ),
                RadioListTile<int>(
                  title: const Text('1 hour before'),
                  value: 60,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Enable browser notifications'),
            subtitle: const Text('Allow this app to show due-task alerts'),
            onTap: widget.onRequestNotificationPermission,
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
              if (confirmed) widget.onClearCompleted();
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
              if (confirmed) widget.onResetAll();
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
