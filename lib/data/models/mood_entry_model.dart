import 'package:hive/hive.dart';

@HiveType(typeId: 13)
enum MoodLevel {
  @HiveField(0)
  great,
  @HiveField(1)
  good,
  @HiveField(2)
  okay,
  @HiveField(3)
  bad,
  @HiveField(4)
  terrible,
}

@HiveType(typeId: 4)
class MoodEntryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  MoodLevel mood;
  @HiveField(3)
  String note;
  @HiveField(4)
  List<String> tags;

  MoodEntryModel({
    required this.id,
    required this.date,
    required this.mood,
    this.note = '',
    this.tags = const [],
  });

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get moodEmoji {
    switch (mood) {
      case MoodLevel.great:
        return '😄';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.okay:
        return '😐';
      case MoodLevel.bad:
        return '😞';
      case MoodLevel.terrible:
        return '😢';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mood': mood.index,
    'note': note,
    'tags': tags,
  };

  factory MoodEntryModel.fromJson(Map<String, dynamic> json) => MoodEntryModel(
    id: json['id'],
    date: DateTime.parse(json['date']),
    mood: MoodLevel.values[json['mood'] ?? 2],
    note: json['note'] ?? '',
    tags: List<String>.from(json['tags'] ?? []),
  );
}
