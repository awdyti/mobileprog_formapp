// lib/providers/task_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/task.dart';

class TasksProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  // Broadcast stream untuk multi-listener
  final StreamController<List<Task>> _broadcastController =
      StreamController<List<Task>>.broadcast();

  Stream<List<Task>> get broadcastStream => _broadcastController.stream;

  List<Task> get tasks => List.unmodifiable(_tasks);

  static const String _prefsTasksKey = 'tasks_json';

  TasksProvider() {
    loadFromPrefs();
  }

  /// Load tasks dari SharedPreferences (dipanggil saat provider dibuat)
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_prefsTasksKey);
      if (s != null && s.isNotEmpty) {
        final decoded = jsonDecode(s) as List<dynamic>;
        _tasks.clear();
        _tasks.addAll(
          decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)),
        );
      } else {
        // Optional: contoh task awal jika belum ada
        _tasks.clear();
        _tasks.addAll([
          Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Belajar Fundamental Dart & Flutter',
          ),
          Task(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            title: 'Selesaikan Proyek To-Do List ini',
            isCompleted: true,
          ),
          Task(
            id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
            title: 'Review materi Flutter UI',
          ),
        ]);
      }
      _broadcastController.add(tasks);
      notifyListeners();
    } catch (e) {
      debugPrint('Error load tasks: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_prefsTasksKey, jsonStr);
    } catch (e) {
      debugPrint('Error save tasks: $e');
    }
  }

  void addTask(String title) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
    );
    _tasks.add(newTask);
    _broadcastController.add(tasks);
    notifyListeners();
    _saveToPrefs();
  }

  void toggleTaskCompletion(int index) {
    if (index < 0 || index >= _tasks.length) return;
    _tasks[index].isCompleted = !_tasks[index].isCompleted;
    _broadcastController.add(tasks);
    notifyListeners();
    _saveToPrefs();
  }

  String deleteTask(int index) {
    final removed = _tasks[index].title;
    _tasks.removeAt(index);
    _broadcastController.add(tasks);
    notifyListeners();
    _saveToPrefs();
    return removed;
  }

  Future<void> clearAll() async {
    _tasks.clear();
    _broadcastController.add(tasks);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTasksKey);
  }

  @override
  void dispose() {
    _broadcastController.close();
    super.dispose();
  }
}
