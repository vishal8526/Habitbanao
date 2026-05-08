part of 'habit_model.dart';

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return HabitModel(
      id: f[0] as String,
      name: f[1] as String,
      description: (f[2] as String?) ?? '',
      emoji: (f[3] as String?) ?? '✅',
      colorValue: (f[4] as int?) ?? 0xFF4CAF50,
      type: (f[5] as HabitType?) ?? HabitType.boolean,
      frequency: (f[6] as FrequencyType?) ?? FrequencyType.daily,
      scheduledDays: (f[7] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5, 6, 7],
      targetCount: (f[8] as int?) ?? 1,
      targetValue: (f[9] as double?) ?? 0,
      unit: (f[10] as String?) ?? '',
      targetDurationMinutes: (f[11] as int?) ?? 0,
      reminderTimes: (f[12] as List?)?.cast<String>() ?? [],
      categoryId: (f[13] as String?) ?? 'General',
      sortOrder: (f[14] as int?) ?? 0,
      isArchived: (f[15] as bool?) ?? false,
      createdAt: f[16] as DateTime?,
      startDate: f[17] as DateTime?,
      endDate: f[18] as DateTime?,
      habitStackParentId: f[19] as String?,
      currentStreak: (f[20] as int?) ?? 0,
      bestStreak: (f[21] as int?) ?? 0,
      timeOfDay: (f[22] as TimeOfDayCategory?) ?? TimeOfDayCategory.anytime,
      intervalDays: (f[23] as int?) ?? 1,
      timesPerWeek: (f[24] as int?) ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.frequency)
      ..writeByte(7)
      ..write(obj.scheduledDays)
      ..writeByte(8)
      ..write(obj.targetCount)
      ..writeByte(9)
      ..write(obj.targetValue)
      ..writeByte(10)
      ..write(obj.unit)
      ..writeByte(11)
      ..write(obj.targetDurationMinutes)
      ..writeByte(12)
      ..write(obj.reminderTimes)
      ..writeByte(13)
      ..write(obj.categoryId)
      ..writeByte(14)
      ..write(obj.sortOrder)
      ..writeByte(15)
      ..write(obj.isArchived)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.startDate)
      ..writeByte(18)
      ..write(obj.endDate)
      ..writeByte(19)
      ..write(obj.habitStackParentId)
      ..writeByte(20)
      ..write(obj.currentStreak)
      ..writeByte(21)
      ..write(obj.bestStreak)
      ..writeByte(22)
      ..write(obj.timeOfDay)
      ..writeByte(23)
      ..write(obj.intervalDays)
      ..writeByte(24)
      ..write(obj.timesPerWeek);
  }
}

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 10;
  @override
  HabitType read(BinaryReader reader) => HabitType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, HabitType obj) => writer.writeByte(obj.index);
}

class FrequencyTypeAdapter extends TypeAdapter<FrequencyType> {
  @override
  final int typeId = 11;
  @override
  FrequencyType read(BinaryReader reader) =>
      FrequencyType.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, FrequencyType obj) =>
      writer.writeByte(obj.index);
}

class TimeOfDayCategoryAdapter extends TypeAdapter<TimeOfDayCategory> {
  @override
  final int typeId = 12;
  @override
  TimeOfDayCategory read(BinaryReader reader) =>
      TimeOfDayCategory.values[reader.readByte()];
  @override
  void write(BinaryWriter writer, TimeOfDayCategory obj) =>
      writer.writeByte(obj.index);
}
