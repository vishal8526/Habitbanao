import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/mood_entry_model.dart';
import '../../core/constants/hive_constants.dart';

class MoodRepository {
  final Box<MoodEntryModel> _box = Hive.box<MoodEntryModel>(
    HiveConstants.moodBox,
  );
  final _uuid = const Uuid();

  List<MoodEntryModel> getAll() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  MoodEntryModel? getForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _box.values.firstWhere((m) => m.dateKey == key);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(
    MoodLevel mood,
    DateTime date, {
    String note = '',
    List<String> tags = const [],
  }) async {
    var existing = getForDate(date);
    if (existing != null) {
      existing.mood = mood;
      existing.note = note;
      existing.tags = tags;
      await existing.save();
    } else {
      final entry = MoodEntryModel(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        mood: mood,
        note: note,
        tags: tags,
      );
      await _box.put(entry.id, entry);
    }
  }
}
