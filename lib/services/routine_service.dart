import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/recurring_task.dart';
import '../models/task.dart';

class RoutineService {
  static const _workStartKey = 'routineWorkStartMinutes';
  static const _workEndKey = 'routineWorkEndMinutes';
  static const _downtimeKey = 'routineDowntime';
  static const _recurringTasksKey = 'routineRecurringTasks';
  static const _materializedPrefix = 'routineMaterialized';

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<({int startMinutes, int endMinutes})> getWorkHours() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      startMinutes: prefs.getInt(_workStartKey) ?? 9 * 60,
      endMinutes: prefs.getInt(_workEndKey) ?? 17 * 60,
    );
  }

  Future<void> saveWorkHours(int startMinutes, int endMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_workStartKey, startMinutes);
    await prefs.setInt(_workEndKey, endMinutes);
  }

  Future<List<Map<String, dynamic>>> getDowntime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_downtimeKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

    Future<void> saveDowntime(List<Map<String, dynamic>> periods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downtimeKey, jsonEncode(periods));
  }

  Future<List<RecurringTask>> getRecurringTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recurringTasksKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => RecurringTask.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveRecurringTasks(List<RecurringTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recurringTasksKey,
      jsonEncode(tasks.map((task) => task.toMap()).toList()),
    );
  }

  Future<void> materializeForDate(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final marker = '$_materializedPrefix-${day.toIso8601String()}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(marker) == true) return;

    final recurringTasks = await getRecurringTasks();
    for (final recurringTask in recurringTasks) {
      if (!_matchesFrequency(recurringTask, day)) continue;

      await _db.insertTask(Task(
        title: recurringTask.title,
        durationMinutes: recurringTask.durationMinutes,
        priority: recurringTask.priority,
        category: recurringTask.category,
        lockedStartTime: recurringTask.lockedStartMinutes == null
            ? null
            : DateTime(
                day.year,
                day.month,
                day.day,
                recurringTask.lockedStartMinutes! ~/ 60,
                recurringTask.lockedStartMinutes! % 60,
              ),
        createdAt: DateTime.now(),
        status: 'unscheduled',
      ));
    }

    await prefs.setBool(marker, true);
  }

  bool _matchesFrequency(RecurringTask recurringTask, DateTime date) {
    switch (recurringTask.frequency) {
      case 'weekly':
        return date.weekday == (recurringTask.recurrenceWeekday ?? date.weekday);
      case 'weekdays':
      case 'workdays':
      case 'schooldays':
        return date.weekday <= DateTime.friday;
      case 'weekends':
      case 'days_off':
        return date.weekday >= DateTime.saturday;
      case 'daily':
      default:
        return true;
    }
  }
}
