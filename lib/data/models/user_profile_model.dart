import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  int totalXP;
  @HiveField(2)
  int level;
  @HiveField(3)
  int totalHabitsCompleted;
  @HiveField(4)
  int longestStreak;
  @HiveField(5)
  DateTime joinDate;
  @HiveField(6)
  int selectedThemeMode;
  @HiveField(7)
  int selectedAccentColorIndex;
  @HiveField(8)
  int weekStartDay;
  @HiveField(9)
  int dayStartHour;
  @HiveField(10)
  String selectedLanguage;

  UserProfileModel({
    this.name = 'User',
    this.totalXP = 0,
    this.level = 1,
    this.totalHabitsCompleted = 0,
    this.longestStreak = 0,
    DateTime? joinDate,
    this.selectedThemeMode = 0,
    this.selectedAccentColorIndex = 0,
    this.weekStartDay = 1,
    this.dayStartHour = 0,
    this.selectedLanguage = 'en',
  }) : joinDate = joinDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name,
    'totalXP': totalXP,
    'level': level,
    'totalHabitsCompleted': totalHabitsCompleted,
    'longestStreak': longestStreak,
    'joinDate': joinDate.toIso8601String(),
    'selectedThemeMode': selectedThemeMode,
    'selectedAccentColorIndex': selectedAccentColorIndex,
    'weekStartDay': weekStartDay,
    'dayStartHour': dayStartHour,
    'selectedLanguage': selectedLanguage,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        name: json['name'] ?? 'User',
        totalXP: json['totalXP'] ?? 0,
        level: json['level'] ?? 1,
        totalHabitsCompleted: json['totalHabitsCompleted'] ?? 0,
        longestStreak: json['longestStreak'] ?? 0,
        joinDate:
            json['joinDate'] != null
                ? DateTime.parse(json['joinDate'])
                : DateTime.now(),
        selectedThemeMode: json['selectedThemeMode'] ?? 0,
        selectedAccentColorIndex: json['selectedAccentColorIndex'] ?? 0,
        weekStartDay: json['weekStartDay'] ?? 1,
        dayStartHour: json['dayStartHour'] ?? 0,
        selectedLanguage: json['selectedLanguage'] ?? 'en',
      );
}
