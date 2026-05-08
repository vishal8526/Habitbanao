import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 5)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  String text;
  @HiveField(3)
  String moodEmoji;
  @HiveField(4)
  List<String> tags;

  JournalEntry({
    required this.id,
    required this.date,
    required this.text,
    this.moodEmoji = '',
    List<String>? tags,
  }) : tags = tags ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'text': text,
    'moodEmoji': moodEmoji,
    'tags': tags,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id: j['id'],
    date: DateTime.parse(j['date']),
    text: j['text'],
    moodEmoji: j['moodEmoji'] ?? '',
    tags: List<String>.from(j['tags'] ?? []),
  );
}
