import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/mood_entry_model.dart';
import '../../data/repositories/mood_repository.dart';

final moodRepositoryProvider = Provider((ref) => MoodRepository());

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});
  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  MoodLevel? _selectedMood;
  final _noteController = TextEditingController();
  final _selectedTags = <String>{};

  @override
  void initState() {
    super.initState();
    final repo = ref.read(moodRepositoryProvider);
    final today = repo.getForDate(DateTime.now());
    if (today != null) {
      _selectedMood = today.mood;
      _noteController.text = today.note;
      _selectedTags.addAll(today.tags);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(moodRepositoryProvider);
    final moods = repo.getAll();
    final recent = moods.take(30).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'How are you feeling today?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                MoodLevel.values.map((m) {
                  final selected = _selectedMood == m;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            selected
                                ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                                : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _moodEmoji(m),
                            style: TextStyle(fontSize: selected ? 36 : 28),
                          ),
                          Text(
                            _moodLabel(m),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          // Tags
          Text('Tags', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                AppConstants.moodTags
                    .map(
                      (t) => FilterChip(
                        label: Text(t),
                        selected: _selectedTags.contains(t),
                        onSelected:
                            (v) => setState(() {
                              v
                                  ? _selectedTags.add(t)
                                  : _selectedTags.remove(t);
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'How was your day?',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Save
          FilledButton(
            onPressed:
                _selectedMood == null
                    ? null
                    : () async {
                      await repo.save(
                        _selectedMood!,
                        DateTime.now(),
                        note: _noteController.text,
                        tags: _selectedTags.toList(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mood saved! 😊')),
                        );
                        setState(() {});
                      }
                    },
            child: const Text('Save Mood'),
          ),
          const SizedBox(height: 24),

          // History chart
          if (recent.isNotEmpty) ...[
            Text(
              'Last 30 Days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          recent.reversed
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  (4 - e.value.mood.index).toDouble(),
                                ),
                              )
                              .toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recent moods
          ...recent
              .take(7)
              .map(
                (m) => ListTile(
                  leading: Text(
                    _moodEmoji(m.mood),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text('${m.date.day}/${m.date.month}/${m.date.year}'),
                  subtitle:
                      m.note.isNotEmpty ? Text(m.note, maxLines: 1) : null,
                  trailing:
                      m.tags.isNotEmpty
                          ? Wrap(
                            spacing: 4,
                            children:
                                m.tags
                                    .take(2)
                                    .map(
                                      (t) => Chip(
                                        label: Text(
                                          t,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                          )
                          : null,
                ),
              ),
        ],
      ),
    );
  }

  String _moodEmoji(MoodLevel m) {
    switch (m) {
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

  String _moodLabel(MoodLevel m) {
    switch (m) {
      case MoodLevel.great:
        return 'Great';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.okay:
        return 'Okay';
      case MoodLevel.bad:
        return 'Bad';
      case MoodLevel.terrible:
        return 'Awful';
    }
  }
}
