import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class AchievementModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String iconEmoji;
  @HiveField(4)
  final String type;
  @HiveField(5)
  final int requiredValue;
  @HiveField(6)
  bool isUnlocked;
  @HiveField(7)
  DateTime? unlockedAt;
  @HiveField(8)
  final int xpReward;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.type,
    required this.requiredValue,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.xpReward,
  });

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
  };

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      AchievementModel(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        iconEmoji: json['iconEmoji'],
        type: json['type'],
        requiredValue: json['requiredValue'],
        isUnlocked: json['isUnlocked'] ?? false,
        unlockedAt:
            json['unlockedAt'] != null
                ? DateTime.parse(json['unlockedAt'])
                : null,
        xpReward: json['xpReward'],
      );
}
