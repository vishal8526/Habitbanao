part of 'habit_entry.dart';

class HabitEntryAdapter extends TypeAdapter<HabitEntry> {
  @override
  final int typeId = 1;

  @override
  HabitEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return HabitEntry(
      id: f[0] as String,
      habitId: f[1] as String,
      date: f[2] as DateTime,
      isCompleted: (f[3] as bool?) ?? false,
      countValue: (f[4] as int?) ?? 0,
      measuredValue: (f[5] as double?) ?? 0,
      durationMinutes: (f[6] as int?) ?? 0,
      note: (f[7] as String?) ?? '',
      moodEmoji: (f[8] as String?) ?? '',
      completedAt: f[9] as DateTime?,
      effortRating: (f[10] as int?) ?? 0,
      isSkipped: (f[11] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HabitEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.countValue)
      ..writeByte(5)
      ..write(obj.measuredValue)
      ..writeByte(6)
      ..write(obj.durationMinutes)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.moodEmoji)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.effortRating)
      ..writeByte(11)
      ..write(obj.isSkipped);
  }
}
