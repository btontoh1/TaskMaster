import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sort_option.dart';
import '../models/todo.dart';

class TodoStorage {
  static const _key = 'todos';
  static const _sortKey = 'defaultSortOption';

  Future<List<Todo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((s) => Todo.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = todos.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<SortOption> loadDefaultSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_sortKey);
    if (saved == null) return SortOption.manual;
    return SortOption.values.byName(saved);
  }

  Future<void> saveDefaultSortOption(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, option.name);
  }
}
