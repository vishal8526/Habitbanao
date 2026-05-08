part of 'journal_entry.dart';

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 5;

  @override
  JournalEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return JournalEntry(
      id: f[0] as String,
      date: f[1] as DateTime,
      text: (f[2] as String?) ?? '',
      moodEmoji: (f[3] as String?) ?? '',
      tags: (f[4] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.moodEmoji)
      ..writeByte(4)
      ..write(obj.tags);
  }
}
