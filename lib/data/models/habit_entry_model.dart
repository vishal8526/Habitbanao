import '../../models/habit_entry.dart';
export '../../models/habit_entry.dart';

typedef HabitEntryModel = HabitEntry;

extension HabitEntryDateKey on HabitEntry {
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
