import 'package:hive/hive.dart';

part 'habit_entry.g.dart';

@HiveType(typeId: 1)
class HabitEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String habitId;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  bool isCompleted;
  @HiveField(4)
  int countValue;
  @HiveField(5)
  double measuredValue;
  @HiveField(6)
  int durationMinutes;
  @HiveField(7)
  String note;
  @HiveField(8)
  String moodEmoji;
  @HiveField(9)
  DateTime? completedAt;
  @HiveField(10)
  int effortRating;
  @HiveField(11)
  bool isSkipped;

  HabitEntry({
    required this.id,
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    this.countValue = 0,
    this.measuredValue = 0,
    this.durationMinutes = 0,
    this.note = '',
    this.moodEmoji = '',
    this.completedAt,
    this.effortRating = 0,
    this.isSkipped = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'date': date.toIso8601String(),
    'isCompleted': isCompleted,
    'countValue': countValue,
    'measuredValue': measuredValue,
    'durationMinutes': durationMinutes,
    'note': note,
    'moodEmoji': moodEmoji,
    'completedAt': completedAt?.toIso8601String(),
    'effortRating': effortRating,
    'isSkipped': isSkipped,
  };

  factory HabitEntry.fromJson(Map<String, dynamic> j) => HabitEntry(
    id: j['id'] as String,
    habitId: j['habitId'] as String,
    date: DateTime.parse(j['date'] as String),
    isCompleted: (j['isCompleted'] as bool?) ?? false,
    countValue: (j['countValue'] as int?) ?? 0,
    measuredValue: ((j['measuredValue'] as num?) ?? 0).toDouble(),
    durationMinutes: (j['durationMinutes'] as int?) ?? 0,
    note: (j['note'] as String?) ?? '',
    moodEmoji: (j['moodEmoji'] as String?) ?? '',
    completedAt:
        j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
    effortRating: (j['effortRating'] as int?) ?? 0,
    isSkipped: (j['isSkipped'] as bool?) ?? false,
  );
}
