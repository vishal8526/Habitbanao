import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

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

extension MoodLevelExt on MoodLevel {
  String get emoji => const ['😄', '🙂', '😐', '😟', '😢'][index];
  String get label => const ['Great', 'Good', 'Okay', 'Bad', 'Terrible'][index];
  int get value => const [5, 4, 3, 2, 1][index];
}

@HiveType(typeId: 4)
class MoodEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  MoodLevel mood;
  @HiveField(3)
  String note;
  @HiveField(4)
  List<String> tags;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note = '',
    List<String>? tags,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mood': mood.index,
    'note': note,
    'tags': tags,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
    id: j['id'],
    date: DateTime.parse(j['date']),
    mood: MoodLevel.values[j['mood'] ?? 2],
    note: j['note'] ?? '',
    tags: List<String>.from(j['tags'] ?? []),
  );
}
