import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/sort_option.dart';
import 'models/todo.dart';
import 'services/notification_service.dart';
import 'settings_page.dart';
import 'storage/todo_storage.dart';
import 'task_form_page.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  static const _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString(_themeModeKey);
      if (saved == null) return;
      setState(() => _themeMode = ThemeMode.values.byName(saved));
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: TodoHomePage(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

enum StatusFilter { all, active, completed }

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<Todo> _todos = [];
  final _storage = TodoStorage();
  late final _notifications = NotificationService(rootScaffoldMessengerKey);
  bool _loading = true;

  StatusFilter _statusFilter = StatusFilter.all;
  SortOption _sortOption = SortOption.manual;
  String? _categoryFilter;
  int _reminderMinutes = 0;

  Timer? _dueCheckTimer;
  final Set<int> _remindedIds = {};
  final Set<int> _dueNotifiedIds = {};
  final Set<int> _overdueNotifiedIds = {};

  @override
  void initState() {
    super.initState();
    _init();
    _dueCheckTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _checkDueNotifications());
  }

  @override
  void dispose() {
    _dueCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final todos = await _storage.load();
    final defaultSort = await _storage.loadDefaultSortOption();
    final reminderMinutes = await _storage.loadReminderMinutes();
    setState(() {
      _todos.addAll(todos);
      _sortOption = defaultSort;
      _reminderMinutes = reminderMinutes;
      _loading = false;
    });
    _checkDueNotifications();
  }

  Future<void> _setDefaultSortOption(SortOption option) async {
    setState(() => _sortOption = option);
    await _storage.saveDefaultSortOption(option);
  }

  Future<void> _setReminderMinutes(int minutes) async {
    setState(() => _reminderMinutes = minutes);
    await _storage.saveReminderMinutes(minutes);
  }

  void _checkDueNotifications() {
    final now = DateTime.now();
    for (final todo in _todos) {
      if (todo.done || todo.dueDate == null) continue;
      final id = identityHashCode(todo);

      if (todo.isOverdue) {
        if (!_overdueNotifiedIds.contains(id)) {
          _overdueNotifiedIds.add(id);
          _notifications.notify('Overdue', '"${todo.title}" was due ${todo.dueLabel}');
        }
        continue;
      }

      if (todo.dueTime == null) continue;
      final dueDateTime = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
        todo.dueTime!.hour,
        todo.dueTime!.minute,
      );

      if (!_dueNotifiedIds.contains(id) && !now.isBefore(dueDateTime)) {
        _dueNotifiedIds.add(id);
        _notifications.notify('Task due now', '"${todo.title}" is due now');
        continue;
      }

      if (_reminderMinutes > 0 && !_remindedIds.contains(id)) {
        final reminderTime =
            dueDateTime.subtract(Duration(minutes: _reminderMinutes));
        if (!now.isBefore(reminderTime) && now.isBefore(dueDateTime)) {
          _remindedIds.add(id);
          _notifications.notify(
            'Upcoming task',
            '"${todo.title}" is due in $_reminderMinutes minutes',
          );
        }
      }
    }
  }

  void _clearCompleted() {
    setState(() {
      _todos.removeWhere((t) => t.done);
    });
    _storage.save(_todos);
  }

  void _resetAll() {
    setState(() {
      _todos.clear();
    });
    _storage.save(_todos);
  }

  Future<void> _openForm({Todo? initial, int? index}) async {
    final existingCategories = _todos
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final result = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          initial: initial,
          existingCategories: existingCategories,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _todos[index] = result;
      } else {
        _todos.add(result);
      }
    });
    _storage.save(_todos);
    _checkDueNotifications();
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].done = !_todos[index].done;
    });
    if (!_todos[index].done) {
      final id = identityHashCode(_todos[index]);
      _remindedIds.remove(id);
      _dueNotifiedIds.remove(id);
      _overdueNotifiedIds.remove(id);
    }
    _storage.save(_todos);
  }

  void _deleteTodo(int index) {
    final removed = _todos[index];
    setState(() {
      _todos.removeAt(index);
    });
    _storage.save(_todos);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${removed.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _todos.insert(index, removed);
              });
              _storage.save(_todos);
            },
          ),
        ),
      );
  }

  List<MapEntry<int, Todo>> _visibleTodos() {
    var entries = _todos.asMap().entries.where((e) {
      final matchesStatus = switch (_statusFilter) {
        StatusFilter.all => true,
        StatusFilter.active => !e.value.done,
        StatusFilter.completed => e.value.done,
      };
      final matchesCategory =
          _categoryFilter == null || e.value.category == _categoryFilter;
      return matchesStatus && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case SortOption.dueDate:
        entries.sort((a, b) {
          final ad = a.value.dueDate;
          final bd = b.value.dueDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case SortOption.priority:
        entries.sort(
          (a, b) => b.value.priority.index.compareTo(a.value.priority.index),
        );
      case SortOption.manual:
        break;
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeCount = _todos.where((t) => !t.done).length;
    final categories = _todos
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final visible = _visibleTodos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Dos'),
        centerTitle: true,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sortOption,
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => [
              for (final option in SortOption.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                  defaultSortOption: _sortOption,
                  onDefaultSortOptionChanged: _setDefaultSortOption,
                  reminderMinutes: _reminderMinutes,
                  onReminderMinutesChanged: _setReminderMinutes,
                  onRequestNotificationPermission: () =>
                      _notifications.requestPermission(),
                  onClearCompleted: _clearCompleted,
                  onResetAll: _resetAll,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_todos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<StatusFilter>(
                      segments: const [
                        ButtonSegment(value: StatusFilter.all, label: Text('All')),
                        ButtonSegment(
                          value: StatusFilter.active,
                          label: Text('Active'),
                        ),
                        ButtonSegment(
                          value: StatusFilter.completed,
                          label: Text('Done'),
                        ),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (selection) =>
                          setState(() => _statusFilter = selection.first),
                    ),
                  ),
                ],
              ),
            ),
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All categories'),
                        selected: _categoryFilter == null,
                        onSelected: (_) =>
                            setState(() => _categoryFilter = null),
                      ),
                      for (final category in categories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _categoryFilter == category,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = category),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$activeCount task${activeCount == 1 ? '' : 's'} remaining',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
          Expanded(
            child: _todos.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet — tap + to add one!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : visible.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks match your filters',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: visible.length,
                        itemBuilder: (context, position) {
                          final entry = visible[position];
                          final index = entry.key;
                          final todo = entry.value;
                          return Dismissible(
                            key: ValueKey(todo.hashCode ^ index),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _deleteTodo(index),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.redAccent,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              onTap: () => _openForm(initial: todo, index: index),
                              leading: Checkbox(
                                value: todo.done,
                                onChanged: (_) => _toggleTodo(index),
                              ),
                              title: Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: todo.done ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: todo.priority.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(todo.priority.label),
                                    ],
                                  ),
                                  if (todo.dueDate != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (todo.isOverdue) ...[
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          const SizedBox(width: 2),
                                        ],
                                        Text(
                                          'Due ${todo.dueLabel}',
                                          style: todo.isOverdue
                                              ? TextStyle(
                                                  color: Theme.of(context).colorScheme.error,
                                                  fontWeight: FontWeight.bold,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  if (todo.category.isNotEmpty)
                                    Chip(
                                      label: Text(todo.category),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteTodo(index),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
