import 'package:hive/hive.dart';
import '../models/achievement_model.dart';
import '../../core/constants/hive_constants.dart';

class AchievementRepository {
  final Box<AchievementModel> _box = Hive.box<AchievementModel>(
    HiveConstants.achievementsBox,
  );

  List<AchievementModel> getAll() => _box.values.toList();

  Future<void> initializeAchievements() async {
    if (_box.isNotEmpty) return;
    final achievements = _defaultAchievements();
    for (final a in achievements) {
      await _box.put(a.id, a);
    }
  }

  Future<AchievementModel?> tryUnlock(String id) async {
    final a = _box.get(id);
    if (a != null && !a.isUnlocked) {
      a.isUnlocked = true;
      a.unlockedAt = DateTime.now();
      await a.save();
      return a;
    }
    return null;
  }

  List<AchievementModel> _defaultAchievements() => [
    AchievementModel(
      id: 'streak_3',
      title: 'First Flame',
      description: '3-day streak',
      iconEmoji: '🔥',
      type: 'streak',
      requiredValue: 3,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'streak_7',
      title: 'Week Warrior',
      description: '7-day streak',
      iconEmoji: '⚔️',
      type: 'streak',
      requiredValue: 7,
      xpReward: 100,
    ),
    AchievementModel(
      id: 'streak_14',
      title: 'Fortnight Fighter',
      description: '14-day streak',
      iconEmoji: '🛡️',
      type: 'streak',
      requiredValue: 14,
      xpReward: 150,
    ),
    AchievementModel(
      id: 'streak_30',
      title: 'Monthly Master',
      description: '30-day streak',
      iconEmoji: '👑',
      type: 'streak',
      requiredValue: 30,
      xpReward: 250,
    ),
    AchievementModel(
      id: 'streak_60',
      title: 'Dual Master',
      description: '60-day streak',
      iconEmoji: '💫',
      type: 'streak',
      requiredValue: 60,
      xpReward: 350,
    ),
    AchievementModel(
      id: 'streak_100',
      title: 'Century Club',
      description: '100-day streak',
      iconEmoji: '💯',
      type: 'streak',
      requiredValue: 100,
      xpReward: 500,
    ),
    AchievementModel(
      id: 'streak_365',
      title: 'Year Champion',
      description: '365-day streak',
      iconEmoji: '🏆',
      type: 'streak',
      requiredValue: 365,
      xpReward: 1000,
    ),
    AchievementModel(
      id: 'comp_1',
      title: 'First Step',
      description: 'Complete 1 habit',
      iconEmoji: '👣',
      type: 'completion',
      requiredValue: 1,
      xpReward: 10,
    ),
    AchievementModel(
      id: 'comp_10',
      title: 'Getting Started',
      description: 'Complete 10 habits',
      iconEmoji: '🌱',
      type: 'completion',
      requiredValue: 10,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'comp_50',
      title: 'Halfway There',
      description: 'Complete 50 habits',
      iconEmoji: '⭐',
      type: 'completion',
      requiredValue: 50,
      xpReward: 100,
    ),
    AchievementModel(
      id: 'comp_100',
      title: 'Centurion',
      description: 'Complete 100 habits',
      iconEmoji: '🎖️',
      type: 'completion',
      requiredValue: 100,
      xpReward: 200,
    ),
    AchievementModel(
      id: 'comp_500',
      title: 'Habit Machine',
      description: 'Complete 500 habits',
      iconEmoji: '⚙️',
      type: 'completion',
      requiredValue: 500,
      xpReward: 400,
    ),
    AchievementModel(
      id: 'comp_1000',
      title: 'Thousand Strong',
      description: 'Complete 1000 habits',
      iconEmoji: '💎',
      type: 'completion',
      requiredValue: 1000,
      xpReward: 500,
    ),
    AchievementModel(
      id: 'comp_5000',
      title: 'Unstoppable',
      description: 'Complete 5000 habits',
      iconEmoji: '🌟',
      type: 'completion',
      requiredValue: 5000,
      xpReward: 1000,
    ),
    AchievementModel(
      id: 'create_1',
      title: 'Beginner',
      description: 'Create first habit',
      iconEmoji: '📝',
      type: 'creation',
      requiredValue: 1,
      xpReward: 10,
    ),
    AchievementModel(
      id: 'create_5',
      title: 'Planner',
      description: 'Create 5 habits',
      iconEmoji: '📋',
      type: 'creation',
      requiredValue: 5,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'create_10',
      title: 'Organizer',
      description: 'Create 10 habits',
      iconEmoji: '📊',
      type: 'creation',
      requiredValue: 10,
      xpReward: 100,
    ),
    AchievementModel(
      id: 'create_25',
      title: 'Habit Collector',
      description: 'Create 25 habits',
      iconEmoji: '🗂️',
      type: 'creation',
      requiredValue: 25,
      xpReward: 200,
    ),
    AchievementModel(
      id: 'perfect_day',
      title: 'Perfect Day',
      description: '100% completion in a day',
      iconEmoji: '🌞',
      type: 'perfect',
      requiredValue: 1,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: '7 perfect days in a row',
      iconEmoji: '🌈',
      type: 'perfect',
      requiredValue: 7,
      xpReward: 200,
    ),
    AchievementModel(
      id: 'perfect_month',
      title: 'Perfect Month',
      description: '30 perfect days',
      iconEmoji: '🏅',
      type: 'perfect',
      requiredValue: 30,
      xpReward: 500,
    ),
    AchievementModel(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Complete a habit before 7 AM',
      iconEmoji: '🐦',
      type: 'special',
      requiredValue: 1,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'comeback',
      title: 'Comeback Kid',
      description: 'Resume after 3+ days break',
      iconEmoji: '💪',
      type: 'special',
      requiredValue: 1,
      xpReward: 75,
    ),
    AchievementModel(
      id: 'variety',
      title: 'Variety Pack',
      description: 'Have habits in 5+ categories',
      iconEmoji: '🎨',
      type: 'special',
      requiredValue: 5,
      xpReward: 100,
    ),
    AchievementModel(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Complete a habit after 11 PM',
      iconEmoji: '🦉',
      type: 'special',
      requiredValue: 1,
      xpReward: 50,
    ),
    AchievementModel(
      id: 'level_5',
      title: 'Leveling Up',
      description: 'Reach level 5',
      iconEmoji: '📈',
      type: 'level',
      requiredValue: 5,
      xpReward: 100,
    ),
    AchievementModel(
      id: 'level_10',
      title: 'Dedicated',
      description: 'Reach level 10',
      iconEmoji: '🎯',
      type: 'level',
      requiredValue: 10,
      xpReward: 200,
    ),
    AchievementModel(
      id: 'level_15',
      title: 'Master',
      description: 'Reach level 15',
      iconEmoji: '🧙',
      type: 'level',
      requiredValue: 15,
      xpReward: 300,
    ),
    AchievementModel(
      id: 'level_20',
      title: 'Titan',
      description: 'Reach level 20',
      iconEmoji: '⚡',
      type: 'level',
      requiredValue: 20,
      xpReward: 400,
    ),
    AchievementModel(
      id: 'level_25',
      title: 'Cosmic',
      description: 'Reach level 25',
      iconEmoji: '🌌',
      type: 'level',
      requiredValue: 25,
      xpReward: 500,
    ),
    AchievementModel(
      id: 'level_30',
      title: 'Legend',
      description: 'Reach level 30',
      iconEmoji: '👼',
      type: 'level',
      requiredValue: 30,
      xpReward: 1000,
    ),
  ];
}
