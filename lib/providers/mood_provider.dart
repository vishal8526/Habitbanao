import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry.dart';
import '../utils/helpers.dart';

const _uuid = Uuid();

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  MoodNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<MoodEntry>('mood_entries');

  void _load() =>
      state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  MoodEntry? forDate(DateTime date) {
    for (final e in state) {
      if (DateHelper.isSameDay(e.date, date)) return e;
    }
    return null;
  }

  Future<void> saveMood(
    DateTime date,
    MoodLevel mood, {
    String note = '',
    List<String> tags = const [],
  }) async {
    final existing = forDate(date);
    if (existing != null) {
      existing.mood = mood;
      existing.note = note;
      existing.tags = List.from(tags);
      await existing.save();
    } else {
      final entry = MoodEntry(
        id: _uuid.v4(),
        date: DateHelper.dateOnly(date),
        mood: mood,
        note: note,
        tags: List.from(tags),
      );
      await _box.put(entry.id, entry);
    }
    _load();
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, List<MoodEntry>>(
  (ref) => MoodNotifier(),
);
