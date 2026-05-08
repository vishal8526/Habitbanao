import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});
  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  // Cached computation
  Object? _cachedStateId;
  List<dynamic> _entries = [];
  int _completedCount = 0;
  double _completionRate = 0;
  List<List<bool?>> _heatmapData = [];
  List<int> _dayCounts = List.filled(7, 0);
  List<int> _dayTotals = List.filled(7, 0);

  void _recompute() {
    final repo = ref.read(habitRepositoryProvider);
    _entries = repo.getEntriesForHabit(widget.habitId);
    _completedCount = _entries.where((e) => e.isCompleted).length;
    _completionRate = repo.getCompletionRate(widget.habitId);

    // Pre-compute heatmap
    final habit = repo.getHabit(widget.habitId);
    if (habit != null) {
      final now = DateTime.now();
      const weeks = 12;
      final startDate = now.subtract(const Duration(days: weeks * 7));
      _heatmapData = List.generate(weeks, (w) {
        return List.generate(7, (d) {
          final date = startDate.add(Duration(days: w * 7 + d));
          if (date.isAfter(now)) return null;
          final entry = repo.getEntry(habit.id, date);
          return entry?.isCompleted ?? false;
        });
      });
    }

    // Pre-compute weekly chart
    _dayCounts = List.filled(7, 0);
    _dayTotals = List.filled(7, 0);
    for (final e in _entries) {
      final day = (e.date as DateTime).weekday - 1;
      _dayTotals[day]++;
      if (e.isCompleted == true) _dayCounts[day]++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(habitRepositoryProvider);
    final habit = repo.getHabit(widget.habitId);
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Habit not found')),
      );
    }

    // Cache-invalidate only when state changes
    final stateId = identityHashCode(ref.watch(habitsProvider));
    if (_cachedStateId != stateId) {
      _cachedStateId = stateId;
      _recompute();
    }

    final color = Color(habit.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-habit/${habit.id}'),
          ),
          PopupMenuButton(
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'archive', child: Text('Archive')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
            onSelected: (v) async {
              if (v == 'archive') {
                await ref
                    .read(habitsProvider.notifier)
                    .archiveHabit(widget.habitId);
                if (context.mounted) context.pop();
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Delete Habit?'),
                        content: const Text(
                          'This will permanently delete this habit and all its entries.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await ref
                      .read(habitsProvider.notifier)
                      .deleteHabit(widget.habitId);
                  if (context.mounted) context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Center(
            child: Text(habit.emoji, style: const TextStyle(fontSize: 56)),
          ),
          Center(
            child: Text(
              habit.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (habit.description.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  habit.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              _statCard(
                theme,
                '🔥',
                '${habit.currentStreak}',
                'Current\nStreak',
                color,
              ),
              const SizedBox(width: 8),
              _statCard(
                theme,
                '⭐',
                '${habit.bestStreak}',
                'Best\nStreak',
                color,
              ),
              const SizedBox(width: 8),
              _statCard(theme, '✅', '$_completedCount', 'Total\nDone', color),
              const SizedBox(width: 8),
              _statCard(
                theme,
                '📊',
                '${(_completionRate * 100).toInt()}%',
                'Rate',
                color,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Heatmap
          Text(
            'Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildHeatmap(context, habit, color),
          const SizedBox(height: 24),

          // Weekly chart
          Text(
            'Weekly Pattern',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: _buildWeeklyChart(habit, color)),
          const SizedBox(height: 24),

          // Recent entries
          Text(
            'Recent Entries',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._entries
              .take(10)
              .map(
                (e) => ListTile(
                  leading: Icon(
                    e.isCompleted
                        ? Icons.check_circle
                        : (e.isSkipped
                            ? Icons.skip_next
                            : Icons.circle_outlined),
                    color:
                        e.isCompleted
                            ? Colors.green
                            : (e.isSkipped ? Colors.orange : Colors.grey),
                  ),
                  title: Text('${e.date.day}/${e.date.month}/${e.date.year}'),
                  subtitle: e.note.isNotEmpty ? Text(e.note) : null,
                  trailing: _entryValue(habit, e),
                ),
              ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme,
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, HabitModel habit, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_heatmapData.length, (w) {
          return Column(
            children: List.generate(7, (d) {
              final cell = w < _heatmapData.length ? _heatmapData[w][d] : null;
              if (cell == null) return const SizedBox(width: 14, height: 14);
              final alpha = cell ? 255 : 38;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: color.withAlpha(alpha),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyChart(HabitModel habit, Color color) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (v, _) => Text(
                    labels[v.toInt() % 7],
                    style: const TextStyle(fontSize: 12),
                  ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(7, (i) {
          final pct =
              _dayTotals[i] > 0 ? (_dayCounts[i] / _dayTotals[i] * 100) : 0.0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pct,
                color: color,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget? _entryValue(HabitModel habit, dynamic entry) {
    switch (habit.type) {
      case HabitType.count:
        return Text('${entry.countValue}/${habit.targetCount}');
      case HabitType.duration:
        return Text('${entry.durationMinutes}m');
      case HabitType.measurable:
        return Text('${entry.measuredValue}');
      default:
        return null;
    }
  }
}
