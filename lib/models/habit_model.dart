import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 10)
enum HabitType {
  @HiveField(0)
  boolean,
  @HiveField(1)
  count,
  @HiveField(2)
  duration,
  @HiveField(3)
  measurable,
}

@HiveType(typeId: 11)
enum FrequencyType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  custom,
  @HiveField(3)
  everyNDays,
  @HiveField(4)
  xTimesPerWeek,
}

@HiveType(typeId: 12)
enum TimeOfDayCategory {
  @HiveField(0)
  morning,
  @HiveField(1)
  afternoon,
  @HiveField(2)
  evening,
  @HiveField(3)
  anytime,
}

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  String emoji;
  @HiveField(4)
  int colorValue;
  @HiveField(5)
  HabitType type;
  @HiveField(6)
  FrequencyType frequency;
  @HiveField(7)
  List<int> scheduledDays;
  @HiveField(8)
  int targetCount;
  @HiveField(9)
  double targetValue;
  @HiveField(10)
  String unit;
  @HiveField(11)
  int targetDurationMinutes;
  @HiveField(12)
  List<String> reminderTimes;
  @HiveField(13)
  String categoryId;
  @HiveField(14)
  int sortOrder;
  @HiveField(15)
  bool isArchived;
  @HiveField(16)
  DateTime createdAt;
  @HiveField(17)
  DateTime startDate;
  @HiveField(18)
  DateTime? endDate;
  @HiveField(19)
  String? habitStackParentId;
  @HiveField(20)
  int currentStreak;
  @HiveField(21)
  int bestStreak;
  @HiveField(22)
  TimeOfDayCategory timeOfDay;
  @HiveField(23)
  int intervalDays;
  @HiveField(24)
  int timesPerWeek;

  HabitModel({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '✅',
    this.colorValue = 0xFF4CAF50,
    this.type = HabitType.boolean,
    this.frequency = FrequencyType.daily,
    List<int>? scheduledDays,
    this.targetCount = 1,
    this.targetValue = 0,
    this.unit = '',
    this.targetDurationMinutes = 0,
    List<String>? reminderTimes,
    this.categoryId = 'General',
    this.sortOrder = 0,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? startDate,
    this.endDate,
    this.habitStackParentId,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.timeOfDay = TimeOfDayCategory.anytime,
    this.intervalDays = 1,
    this.timesPerWeek = 1,
  }) : scheduledDays = scheduledDays ?? [1, 2, 3, 4, 5, 6, 7],
       reminderTimes = reminderTimes ?? [],
       createdAt = createdAt ?? DateTime.now(),
       startDate = startDate ?? DateTime.now();

  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    int? colorValue,
    HabitType? type,
    FrequencyType? frequency,
    List<int>? scheduledDays,
    int? targetCount,
    double? targetValue,
    String? unit,
    int? targetDurationMinutes,
    List<String>? reminderTimes,
    String? categoryId,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? habitStackParentId,
    int? currentStreak,
    int? bestStreak,
    TimeOfDayCategory? timeOfDay,
    int? intervalDays,
    int? timesPerWeek,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      scheduledDays: scheduledDays ?? List<int>.from(this.scheduledDays),
      targetCount: targetCount ?? this.targetCount,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      reminderTimes: reminderTimes ?? List<String>.from(this.reminderTimes),
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      habitStackParentId: habitStackParentId ?? this.habitStackParentId,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      intervalDays: intervalDays ?? this.intervalDays,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'colorValue': colorValue,
    'type': type.index,
    'frequency': frequency.index,
    'scheduledDays': scheduledDays,
    'targetCount': targetCount,
    'targetValue': targetValue,
    'unit': unit,
    'targetDurationMinutes': targetDurationMinutes,
    'reminderTimes': reminderTimes,
    'categoryId': categoryId,
    'sortOrder': sortOrder,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'habitStackParentId': habitStackParentId,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'timeOfDay': timeOfDay.index,
    'intervalDays': intervalDays,
    'timesPerWeek': timesPerWeek,
  };

  factory HabitModel.fromJson(Map<String, dynamic> j) => HabitModel(
    id: j['id'],
    name: j['name'],
    description: j['description'] ?? '',
    emoji: j['emoji'] ?? '✅',
    colorValue: j['colorValue'] ?? 0xFF4CAF50,
    type: HabitType.values[j['type'] ?? 0],
    frequency: FrequencyType.values[j['frequency'] ?? 0],
    scheduledDays: List<int>.from(j['scheduledDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
    targetCount: j['targetCount'] ?? 1,
    targetValue: (j['targetValue'] ?? 0).toDouble(),
    unit: j['unit'] ?? '',
    targetDurationMinutes: j['targetDurationMinutes'] ?? 0,
    reminderTimes: List<String>.from(j['reminderTimes'] ?? []),
    categoryId: j['categoryId'] ?? 'General',
    sortOrder: j['sortOrder'] ?? 0,
    isArchived: j['isArchived'] ?? false,
    createdAt: DateTime.parse(j['createdAt']),
    startDate: DateTime.parse(j['startDate']),
    endDate: j['endDate'] != null ? DateTime.parse(j['endDate']) : null,
    habitStackParentId: j['habitStackParentId'],
    currentStreak: j['currentStreak'] ?? 0,
    bestStreak: j['bestStreak'] ?? 0,
    timeOfDay: TimeOfDayCategory.values[j['timeOfDay'] ?? 3],
    intervalDays: j['intervalDays'] ?? 1,
    timesPerWeek: j['timesPerWeek'] ?? 1,
  );

  bool isScheduledFor(DateTime date) {
    if (isArchived) return false;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(s)) return false;
    if (endDate != null && d.isAfter(endDate!)) return false;
    switch (frequency) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.weekly:
      case FrequencyType.custom:
        return scheduledDays.contains(date.weekday);
      case FrequencyType.everyNDays:
        return intervalDays > 0 && d.difference(s).inDays % intervalDays == 0;
      case FrequencyType.xTimesPerWeek:
        return true;
    }
  }

  /// Alias for [isScheduledFor] used by data repositories.
  bool isScheduledForDate(DateTime date) => isScheduledFor(date);
}
