import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/habit_model.dart';
import '../models/habit_entry.dart';
import '../providers/habit_provider.dart';
import '../utils/helpers.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitProvider);
    HabitModel? habit;
    for (final h in state.habits) {
      if (h.id == habitId) {
        habit = h;
        break;
      }
    }
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not found')),
      );
    }
    final habitNN = habit;

    final entries = state.entriesForHabit(habitId);
    final completed = entries.where((e) => e.isCompleted).toList();
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);

    final ds =
        DateHelper.today()
            .difference(DateHelper.dateOnly(habit.createdAt))
            .inDays +
        1;
    int sched = 0;
    for (int i = 0; i < ds; i++) {
      if (habit.isScheduledFor(
        DateHelper.dateOnly(habit.createdAt).add(Duration(days: i)),
      )) {
        sched++;
      }
    }
    final rate = sched > 0 ? (completed.length / sched * 100).round() : 0;

    final wd = List.generate(7, (dow) {
      final de = entries.where((e) => e.date.weekday == dow + 1).toList();
      final c = de.where((e) => e.isCompleted).length;
      return de.isNotEmpty ? c / de.length : 0.0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji} ${habit.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-habit/${habit!.id}'),
          ),
          PopupMenuButton(
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'archive', child: Text('Archive')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
            onSelected: (v) {
              if (v == 'archive') {
                ref.read(habitProvider.notifier).archiveHabit(habit!.id);
                context.pop();
              } else if (v == 'delete') {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Delete Habit?'),
                        content: const Text('This cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(habitProvider.notifier)
                                  .deleteHabit(habit!.id);
                              Navigator.pop(context);
                              context.pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _S(
                l: 'Current\nStreak',
                v: '${habit.currentStreak}',
                i: '🔥',
                c: color,
              ),
              _S(l: 'Best\nStreak', v: '${habit.bestStreak}', i: '⭐', c: color),
              _S(l: 'Total\nDone', v: '${completed.length}', i: '✅', c: color),
              _S(l: 'Rate', v: '$rate%', i: '📊', c: color),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _heatmap(context, habit, entries, color),
          const SizedBox(height: 24),
          Text(
            'Weekly Pattern',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(enabled: false),
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
                            const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v
                                .toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: wd[i],
                        color: color,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          ...entries
              .take(10)
              .map(
                (e) => ListTile(
                  leading: Text(
                    e.isCompleted ? '✅' : (e.isSkipped ? '⏭️' : '⬜'),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(DateHelper.formatDate(e.date)),
                  subtitle: e.note.isNotEmpty ? Text(e.note) : null,
                  trailing: _ev(habitNN, e),
                ),
              ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No entries yet.')),
            ),
        ],
      ),
    );
  }

  Widget _heatmap(
    BuildContext ctx,
    HabitModel h,
    List<HabitEntry> entries,
    Color color,
  ) {
    final today = DateHelper.today();
    const weeks = 12;
    final start = today.subtract(const Duration(days: weeks * 7));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          weeks,
          (w) => Column(
            children: List.generate(7, (d) {
              final date = DateHelper.dateOnly(
                start,
              ).add(Duration(days: w * 7 + d));
              if (date.isAfter(today)) {
                return const SizedBox(width: 14, height: 14);
              }
              final done = entries.any(
                (e) => DateHelper.isSameDay(e.date, date) && e.isCompleted,
              );
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color:
                      done
                          ? color
                          : (h.isScheduledFor(date)
                              ? Theme.of(
                                ctx,
                              ).colorScheme.surfaceContainerHighest
                              : Colors.transparent),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget? _ev(HabitModel h, HabitEntry e) => switch (h.type) {
    HabitType.count => Text('${e.countValue}/${h.targetCount}'),
    HabitType.duration => Text(DurationHelper.format(e.durationMinutes)),
    HabitType.measurable => Text('${e.measuredValue}/${h.targetValue}'),
    _ => null,
  };
}

class _S extends StatelessWidget {
  final String l, v, i;
  final Color c;
  const _S({
    required this.l,
    required this.v,
    required this.i,
    required this.c,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Text(i, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              v,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: c,
              ),
            ),
            Text(
              l,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
