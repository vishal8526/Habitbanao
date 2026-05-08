import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});
  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  MoodLevel? _selectedMood;
  final _noteController = TextEditingController();
  final _selectedTags = <String>{};

  // Cached chart data — recomputed only when mood list changes
  int _cachedMoodStateId = 0;
  List<FlSpot> _cachedChartData = const [];

  @override
  void initState() {
    super.initState();
    final today = ref.read(moodProvider.notifier).forDate(DateHelper.today());
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

  void _recomputeChart(List<MoodEntry> moods) {
    final stateId = identityHashCode(moods);
    if (stateId == _cachedMoodStateId) return;
    _cachedMoodStateId = stateId;

    // Build O(1) date lookup from moods list
    final moodByDate = <String, MoodEntry>{};
    for (final e in moods) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      moodByDate[key] = e;
    }

    final data = <FlSpot>[];
    for (int i = 29; i >= 0; i--) {
      final date = DateHelper.today().subtract(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final entry = moodByDate[key];
      data.add(FlSpot((29 - i).toDouble(), entry?.mood.value.toDouble() ?? 0));
    }
    _cachedChartData = data;
  }

  @override
  Widget build(BuildContext context) {
    final moods = ref.watch(moodProvider);
    final theme = Theme.of(context);

    _recomputeChart(moods);
    final chartData = _cachedChartData;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'How are you feeling today?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                MoodLevel.values.map((m) {
                  final selected = _selectedMood == m;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? theme.colorScheme.primaryContainer
                                : null,
                        borderRadius: BorderRadius.circular(12),
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
                            m.emoji,
                            style: TextStyle(fontSize: selected ? 36 : 28),
                          ),
                          Text(
                            m.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: selected ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
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
                              if (v) {
                                _selectedTags.add(t);
                              } else {
                                _selectedTags.remove(t);
                              }
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                _selectedMood == null
                    ? null
                    : () async {
                      await ref
                          .read(moodProvider.notifier)
                          .saveMood(
                            DateTime.now(),
                            _selectedMood!,
                            note: _noteController.text,
                            tags: _selectedTags.toList(),
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mood saved! 😊')),
                        );
                      }
                    },
            child: const Text('Save Mood'),
          ),
          const SizedBox(height: 24),
          if (moods.isNotEmpty) ...[
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
                      spots: chartData,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...moods
                .take(7)
                .map(
                  (m) => ListTile(
                    leading: Text(
                      m.mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(DateHelper.formatDate(m.date)),
                    subtitle: m.note.isNotEmpty ? Text(m.note) : null,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
