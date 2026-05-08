import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../core/constants/hive_constants.dart';

class HabitRepository {
  final Box<HabitModel> _habitsBox = Hive.box<HabitModel>(
    HiveConstants.habitsBox,
  );
  final Box<HabitEntryModel> _entriesBox = Hive.box<HabitEntryModel>(
    HiveConstants.entriesBox,
  );
  final _uuid = const Uuid();

  List<HabitModel> getAllHabits() => _habitsBox.values.toList();

  List<HabitModel> getActiveHabits() =>
      _habitsBox.values.where((h) => !h.isArchived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<HabitModel> getHabitsForDate(DateTime date) =>
      getActiveHabits().where((h) => h.isScheduledForDate(date)).toList();

  HabitModel? getHabit(String id) {
    try {
      return _habitsBox.values.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
    final entriesToDelete =
        _entriesBox.values.where((e) => e.habitId == id).toList();
    for (final entry in entriesToDelete) {
      await entry.delete();
    }
  }

  Future<void> reorderHabits(List<HabitModel> habits) async {
    for (int i = 0; i < habits.length; i++) {
      habits[i].sortOrder = i;
      await habits[i].save();
    }
  }

  // Entries
  List<HabitEntryModel> getAllEntries() => _entriesBox.values.toList();

  List<HabitEntryModel> getEntriesForHabit(String habitId) =>
      _entriesBox.values.where((e) => e.habitId == habitId).toList();

  HabitEntryModel? getEntry(String habitId, DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _entriesBox.values.firstWhere(
        (e) => e.habitId == habitId && e.dateKey == dateKey,
      );
    } catch (_) {
      return null;
    }
  }

  List<HabitEntryModel> getEntriesForDate(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _entriesBox.values.where((e) => e.dateKey == dateKey).toList();
  }

  Future<HabitEntryModel> createOrUpdateEntry({
    required String habitId,
    required DateTime date,
    bool? isCompleted,
    int? countValue,
    double? measuredValue,
    int? durationMinutes,
    String? note,
    bool? isSkipped,
  }) async {
    var entry = getEntry(habitId, date);
    entry ??= HabitEntryModel(
        id: _uuid.v4(),
        habitId: habitId,
        date: DateTime(date.year, date.month, date.day),
      );
    if (isCompleted != null) {
      entry.isCompleted = isCompleted;
      entry.completedAt = isCompleted ? DateTime.now() : null;
    }
    if (countValue != null) entry.countValue = countValue;
    if (measuredValue != null) entry.measuredValue = measuredValue;
    if (durationMinutes != null) entry.durationMinutes = durationMinutes;
    if (note != null) entry.note = note;
    if (isSkipped != null) entry.isSkipped = isSkipped;

    await _entriesBox.put(entry.id, entry);
    return entry;
  }

  int calculateStreak(String habitId) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;
    final entries = getEntriesForHabit(habitId);
    if (entries.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    for (int i = 0; i < 365; i++) {
      final date = checkDate.subtract(Duration(days: i));
      if (!habit.isScheduledForDate(date)) continue;

      final entry = getEntry(habitId, date);
      if (entry != null && entry.isCompleted) {
        streak++;
      } else if (i == 0) {
        continue; // today might not be completed yet
      } else {
        break;
      }
    }
    return streak;
  }

  double getCompletionRate(String habitId, {int days = 30}) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;
    final now = DateTime.now();
    int scheduled = 0;
    int completed = 0;
    for (int i = 0; i < days; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      if (!habit.isScheduledForDate(date)) continue;
      scheduled++;
      final entry = getEntry(habitId, date);
      if (entry != null && entry.isCompleted) completed++;
    }
    return scheduled == 0 ? 0 : completed / scheduled;
  }

  double getDailyCompletionRate(DateTime date) {
    final habits = getHabitsForDate(date);
    if (habits.isEmpty) return 0;
    int completed = 0;
    for (final habit in habits) {
      final entry = getEntry(habit.id, date);
      if (entry != null && entry.isCompleted) completed++;
    }
    return completed / habits.length;
  }
}
