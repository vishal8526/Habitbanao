part of 'user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 3;

  @override
  UserProfile read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      f[reader.readByte()] = reader.read();
    }
    return UserProfile(
      name: (f[0] as String?) ?? 'User',
      totalXP: (f[1] as int?) ?? 0,
      level: (f[2] as int?) ?? 1,
      totalHabitsCompleted: (f[3] as int?) ?? 0,
      longestStreak: (f[4] as int?) ?? 0,
      joinDate: f[5] as DateTime?,
      selectedThemeMode: (f[6] as int?) ?? 0,
      selectedAccentColor: (f[7] as int?) ?? 0xFF4CAF50,
      weekStartDay: (f[8] as int?) ?? 1,
      dayStartHour: (f[9] as int?) ?? 0,
      selectedLanguage: (f[10] as String?) ?? 'en',
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.totalXP)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.totalHabitsCompleted)
      ..writeByte(4)
      ..write(obj.longestStreak)
      ..writeByte(5)
      ..write(obj.joinDate)
      ..writeByte(6)
      ..write(obj.selectedThemeMode)
      ..writeByte(7)
      ..write(obj.selectedAccentColor)
      ..writeByte(8)
      ..write(obj.weekStartDay)
      ..writeByte(9)
      ..write(obj.dayStartHour)
      ..writeByte(10)
      ..write(obj.selectedLanguage);
  }
}
