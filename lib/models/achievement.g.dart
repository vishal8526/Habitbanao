part of 'achievement.dart';

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 2;

  @override
  Achievement read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return Achievement(
      id: f[0] as String,
      title: f[1] as String,
      description: f[2] as String,
      iconEmoji: f[3] as String,
      type: f[4] as String,
      requiredValue: f[5] as int,
      isUnlocked: (f[6] as bool?) ?? false,
      unlockedAt: f[7] as DateTime?,
      xpReward: f[8] as int,
      currentProgress: (f[9] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconEmoji)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.requiredValue)
      ..writeByte(6)
      ..write(obj.isUnlocked)
      ..writeByte(7)
      ..write(obj.unlockedAt)
      ..writeByte(8)
      ..write(obj.xpReward)
      ..writeByte(9)
      ..write(obj.currentProgress);
  }
}
