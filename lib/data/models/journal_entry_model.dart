import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class JournalEntryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  String text;
  @HiveField(3)
  String? moodEmoji;
  @HiveField(4)
  List<String> tags;

  JournalEntryModel({
    required this.id,
    required this.date,
    this.text = '',
    this.moodEmoji,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'text': text,
    'moodEmoji': moodEmoji,
    'tags': tags,
  };

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) =>
      JournalEntryModel(
        id: json['id'],
        date: DateTime.parse(json['date']),
        text: json['text'] ?? '',
        moodEmoji: json['moodEmoji'],
        tags: List<String>.from(json['tags'] ?? []),
      );
}
