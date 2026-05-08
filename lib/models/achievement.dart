import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 2)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  String iconEmoji;
  @HiveField(4)
  String type;
  @HiveField(5)
  int requiredValue;
  @HiveField(6)
  bool isUnlocked;
  @HiveField(7)
  DateTime? unlockedAt;
  @HiveField(8)
  int xpReward;
  @HiveField(9)
  int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.type,
    required this.requiredValue,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.xpReward,
    this.currentProgress = 0,
  });

  double get progressPercent =>
      requiredValue > 0 ? (currentProgress / requiredValue).clamp(0.0, 1.0) : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconEmoji': iconEmoji,
    'type': type,
    'requiredValue': requiredValue,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'xpReward': xpReward,
    'currentProgress': currentProgress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    iconEmoji: json['iconEmoji'] as String,
    type: json['type'] as String,
    requiredValue: json['requiredValue'] as int,
    isUnlocked: (json['isUnlocked'] as bool?) ?? false,
    unlockedAt:
        json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
    xpReward: json['xpReward'] as int,
    currentProgress: (json['currentProgress'] as int?) ?? 0,
  );
}
