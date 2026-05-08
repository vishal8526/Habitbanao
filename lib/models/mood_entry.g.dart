part of 'mood_entry.dart';

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 4;

  @override
  MoodEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return MoodEntry(
      id: f[0] as String,
      date: f[1] as DateTime,
      mood: f[2] as MoodLevel,
      note: (f[3] as String?) ?? '',
      tags: (f[4] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.tags);
  }
}

class MoodLevelAdapter extends TypeAdapter<MoodLevel> {
  @override
  final int typeId = 13;
  @override
  MoodLevel read(BinaryReader reader) => MoodLevel.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, MoodLevel obj) => writer.writeByte(obj.index);
}
