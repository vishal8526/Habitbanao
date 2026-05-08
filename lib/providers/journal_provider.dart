import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';

const _uuid = Uuid();

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier() : super([]) {
    _load();
  }

  final _box = Hive.box<JournalEntry>('journal_entries');

  void _load() =>
      state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(
    String text, {
    String moodEmoji = '',
    List<String> tags = const [],
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      text: text,
      moodEmoji: moodEmoji,
      tags: List.from(tags),
    );
    await _box.put(entry.id, entry);
    _load();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _load();
  }

  List<JournalEntry> search(String query) {
    final q = query.toLowerCase();
    return state
        .where(
          (e) =>
              e.text.toLowerCase().contains(q) ||
              e.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, List<JournalEntry>>(
      (ref) => JournalNotifier(),
    );
