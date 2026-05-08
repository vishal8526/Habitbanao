import '../../data/models/habit_model.dart';

class HabitTemplate {
  final String name;
  final String emoji;
  final String category;
  final HabitType type;
  final int targetCount;
  final double targetValue;
  final String unit;
  final int targetDurationMinutes;
  final int colorValue;

  const HabitTemplate({
    required this.name,
    required this.emoji,
    required this.category,
    required this.type,
    this.targetCount = 1,
    this.targetValue = 0,
    this.unit = '',
    this.targetDurationMinutes = 0,
    this.colorValue = 0xFF42A5F5,
  });
}

class HabitTemplates {
  static const List<HabitTemplate> all = [
    // Health (8)
    HabitTemplate(
      name: 'Drink Water',
      emoji: '💧',
      category: 'Health',
      type: HabitType.count,
      targetCount: 8,
      unit: 'glasses',
      colorValue: 0xFF29B6F6,
    ),
    HabitTemplate(
      name: 'Take Vitamins',
      emoji: '💊',
      category: 'Health',
      type: HabitType.boolean,
      colorValue: 0xFF66BB6A,
    ),
    HabitTemplate(
      name: 'Eat Fruits',
      emoji: '🍎',
      category: 'Health',
      type: HabitType.count,
      targetCount: 3,
      unit: 'servings',
      colorValue: 0xFFEF5350,
    ),
    HabitTemplate(
      name: 'Sleep 8 Hours',
      emoji: '😴',
      category: 'Health',
      type: HabitType.measurable,
      targetValue: 8,
      unit: 'hours',
      colorValue: 0xFF7E57C2,
    ),
    HabitTemplate(
      name: 'No Sugar',
      emoji: '🚫',
      category: 'Health',
      type: HabitType.boolean,
      colorValue: 0xFFFF7043,
    ),
    HabitTemplate(
      name: 'Brush Teeth',
      emoji: '🦷',
      category: 'Health',
      type: HabitType.count,
      targetCount: 2,
      unit: 'times',
      colorValue: 0xFF26C6DA,
    ),
    HabitTemplate(
      name: 'Skincare Routine',
      emoji: '🧴',
      category: 'Health',
      type: HabitType.boolean,
      colorValue: 0xFFEC407A,
    ),
    HabitTemplate(
      name: 'No Alcohol',
      emoji: '🍷',
      category: 'Health',
      type: HabitType.boolean,
      colorValue: 0xFF8D6E63,
    ),

    // Fitness (6)
    HabitTemplate(
      name: 'Workout',
      emoji: '🏋️',
      category: 'Fitness',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFFEF5350,
    ),
    HabitTemplate(
      name: 'Walk 10K Steps',
      emoji: '🚶',
      category: 'Fitness',
      type: HabitType.measurable,
      targetValue: 10000,
      unit: 'steps',
      colorValue: 0xFF66BB6A,
    ),
    HabitTemplate(
      name: 'Run',
      emoji: '🏃',
      category: 'Fitness',
      type: HabitType.measurable,
      targetValue: 5,
      unit: 'km',
      colorValue: 0xFFFF9800,
    ),
    HabitTemplate(
      name: 'Stretching',
      emoji: '🤸',
      category: 'Fitness',
      type: HabitType.duration,
      targetDurationMinutes: 15,
      colorValue: 0xFFAB47BC,
    ),
    HabitTemplate(
      name: 'Cycling',
      emoji: '🚴',
      category: 'Fitness',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFF42A5F5,
    ),
    HabitTemplate(
      name: 'Swimming',
      emoji: '🏊',
      category: 'Fitness',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFF26C6DA,
    ),

    // Mindfulness (5)
    HabitTemplate(
      name: 'Meditate',
      emoji: '🧘',
      category: 'Mindfulness',
      type: HabitType.duration,
      targetDurationMinutes: 10,
      colorValue: 0xFF7E57C2,
    ),
    HabitTemplate(
      name: 'Journaling',
      emoji: '📝',
      category: 'Mindfulness',
      type: HabitType.boolean,
      colorValue: 0xFFFFCA28,
    ),
    HabitTemplate(
      name: 'Gratitude',
      emoji: '🙏',
      category: 'Mindfulness',
      type: HabitType.count,
      targetCount: 3,
      unit: 'things',
      colorValue: 0xFFFF9800,
    ),
    HabitTemplate(
      name: 'Deep Breathing',
      emoji: '🌬️',
      category: 'Mindfulness',
      type: HabitType.duration,
      targetDurationMinutes: 5,
      colorValue: 0xFF26A69A,
    ),
    HabitTemplate(
      name: 'No Phone Before Bed',
      emoji: '📵',
      category: 'Mindfulness',
      type: HabitType.boolean,
      colorValue: 0xFF78909C,
    ),

    // Productivity (6)
    HabitTemplate(
      name: 'Wake Up Early',
      emoji: '⏰',
      category: 'Productivity',
      type: HabitType.boolean,
      colorValue: 0xFFFFA726,
    ),
    HabitTemplate(
      name: 'Plan Tomorrow',
      emoji: '📋',
      category: 'Productivity',
      type: HabitType.boolean,
      colorValue: 0xFF5C6BC0,
    ),
    HabitTemplate(
      name: 'Deep Work',
      emoji: '💻',
      category: 'Productivity',
      type: HabitType.duration,
      targetDurationMinutes: 120,
      colorValue: 0xFF42A5F5,
    ),
    HabitTemplate(
      name: 'Inbox Zero',
      emoji: '📧',
      category: 'Productivity',
      type: HabitType.boolean,
      colorValue: 0xFF26A69A,
    ),
    HabitTemplate(
      name: 'Review Goals',
      emoji: '🎯',
      category: 'Productivity',
      type: HabitType.boolean,
      colorValue: 0xFFEF5350,
    ),
    HabitTemplate(
      name: 'No Social Media',
      emoji: '📱',
      category: 'Productivity',
      type: HabitType.boolean,
      colorValue: 0xFF78909C,
    ),

    // Learning (5)
    HabitTemplate(
      name: 'Read',
      emoji: '📖',
      category: 'Learning',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFF8D6E63,
    ),
    HabitTemplate(
      name: 'Learn Language',
      emoji: '🗣️',
      category: 'Learning',
      type: HabitType.duration,
      targetDurationMinutes: 15,
      colorValue: 0xFFAB47BC,
    ),
    HabitTemplate(
      name: 'Online Course',
      emoji: '🎓',
      category: 'Learning',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFF5C6BC0,
    ),
    HabitTemplate(
      name: 'Practice Coding',
      emoji: '👨‍💻',
      category: 'Learning',
      type: HabitType.duration,
      targetDurationMinutes: 60,
      colorValue: 0xFF66BB6A,
    ),
    HabitTemplate(
      name: 'Listen to Podcast',
      emoji: '🎧',
      category: 'Learning',
      type: HabitType.boolean,
      colorValue: 0xFFFF7043,
    ),

    // Social (3)
    HabitTemplate(
      name: 'Call Family',
      emoji: '👨‍👩‍👧',
      category: 'Social',
      type: HabitType.boolean,
      colorValue: 0xFFEC407A,
    ),
    HabitTemplate(
      name: 'Message a Friend',
      emoji: '💬',
      category: 'Social',
      type: HabitType.boolean,
      colorValue: 0xFF42A5F5,
    ),
    HabitTemplate(
      name: 'Random Act of Kindness',
      emoji: '💝',
      category: 'Social',
      type: HabitType.boolean,
      colorValue: 0xFFFF9800,
    ),

    // Finance (3)
    HabitTemplate(
      name: 'Track Expenses',
      emoji: '💰',
      category: 'Finance',
      type: HabitType.boolean,
      colorValue: 0xFF66BB6A,
    ),
    HabitTemplate(
      name: 'Save Money',
      emoji: '🏦',
      category: 'Finance',
      type: HabitType.measurable,
      targetValue: 10,
      unit: 'dollars',
      colorValue: 0xFF26A69A,
    ),
    HabitTemplate(
      name: 'No Impulse Buying',
      emoji: '🛒',
      category: 'Finance',
      type: HabitType.boolean,
      colorValue: 0xFFFF7043,
    ),

    // Creativity (3)
    HabitTemplate(
      name: 'Draw/Sketch',
      emoji: '🎨',
      category: 'Creativity',
      type: HabitType.duration,
      targetDurationMinutes: 20,
      colorValue: 0xFFEC407A,
    ),
    HabitTemplate(
      name: 'Play Music',
      emoji: '🎸',
      category: 'Creativity',
      type: HabitType.duration,
      targetDurationMinutes: 30,
      colorValue: 0xFFAB47BC,
    ),
    HabitTemplate(
      name: 'Write',
      emoji: '✍️',
      category: 'Creativity',
      type: HabitType.measurable,
      targetValue: 500,
      unit: 'words',
      colorValue: 0xFF5C6BC0,
    ),
  ];

  static List<HabitTemplate> getByCategory(String category) =>
      all.where((t) => t.category == category).toList();
}
