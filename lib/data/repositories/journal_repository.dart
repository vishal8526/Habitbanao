import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry_model.dart';
import '../../core/constants/hive_constants.dart';

class JournalRepository {
  final Box<JournalEntryModel> _box = Hive.box<JournalEntryModel>(
    HiveConstants.journalBox,
  );
  final _uuid = const Uuid();

  List<JournalEntryModel> getAll() =>
      _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(
    String text, {
    String? moodEmoji,
    List<String> tags = const [],
  }) async {
    final entry = JournalEntryModel(
      id: _uuid.v4(),
      date: DateTime.now(),
      text: text,
      moodEmoji: moodEmoji,
      tags: tags,
    );
    await _box.put(entry.id, entry);
  }

  Future<void> delete(String id) async => await _box.delete(id);

  List<JournalEntryModel> search(String query) =>
      _box.values
          .where((j) => j.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
}
