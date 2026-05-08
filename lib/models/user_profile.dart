import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 3)
class UserProfile extends HiveObject {
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
  int selectedAccentColor;
  @HiveField(8)
  int weekStartDay;
  @HiveField(9)
  int dayStartHour;
  @HiveField(10)
  String selectedLanguage;

  UserProfile({
    this.name = 'User',
    this.totalXP = 0,
    this.level = 1,
    this.totalHabitsCompleted = 0,
    this.longestStreak = 0,
    DateTime? joinDate,
    this.selectedThemeMode = 0,
    this.selectedAccentColor = 0xFF4CAF50,
    this.weekStartDay = 1,
    this.dayStartHour = 0,
    this.selectedLanguage = 'en',
  }) : joinDate = joinDate ?? DateTime.now();

  static const _levelNames = [
    'Beginner',
    'Novice',
    'Apprentice',
    'Learner',
    'Student',
    'Adept',
    'Practitioner',
    'Journeyman',
    'Expert',
    'Veteran',
    'Elite',
    'Master',
    'Grandmaster',
    'Champion',
    'Hero',
    'Titan',
    'Mythic',
    'Legendary',
    'Immortal',
    'Transcendent',
    'Ascendant',
    'Celestial',
    'Divine',
    'Ethereal',
    'Cosmic',
    'Omniscient',
    'Supreme',
    'Ultimate',
    'Infinite',
    'Legend',
  ];

  static const _thresholds = [
    0,
    100,
    250,
    500,
    800,
    1200,
    1700,
    2300,
    3000,
    3800,
    4700,
    5700,
    6800,
    8000,
    9500,
    11000,
    13000,
    15000,
    17500,
    20000,
    23000,
    26000,
    29500,
    33000,
    37000,
    41000,
    45000,
    50000,
    55000,
    60000,
  ];

  String get levelName => _levelNames[(level - 1).clamp(0, 29)];
  int get xpForNextLevel => level >= 30 ? 60000 : _thresholds[level];
  int get xpForCurrentLevel => _thresholds[(level - 1).clamp(0, 29)];

  double get levelProgress {
    final cur = totalXP - xpForCurrentLevel;
    final needed = xpForNextLevel - xpForCurrentLevel;
    return needed <= 0 ? 1.0 : (cur / needed).clamp(0.0, 1.0);
  }

  void addXP(int xp) {
    totalXP += xp;
    while (level < 30 && totalXP >= xpForNextLevel) {
      level++;
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'totalXP': totalXP,
    'level': level,
    'totalHabitsCompleted': totalHabitsCompleted,
    'longestStreak': longestStreak,
    'joinDate': joinDate.toIso8601String(),
    'selectedThemeMode': selectedThemeMode,
    'selectedAccentColor': selectedAccentColor,
    'weekStartDay': weekStartDay,
    'dayStartHour': dayStartHour,
    'selectedLanguage': selectedLanguage,
  };
}
