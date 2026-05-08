import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../utils/helpers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _rangeIdx = 0;

  // Cached computation results
  int _cachedRange = -1;
  double _cachedOverall = 0;
  List<FlSpot> _cachedTrend = [];
  List<double> _cachedDow = List.filled(7, 0);
  List<(HabitModel, double)> _cachedHabitRates = [];
  Object? _cachedStateIdentity;

  void _recompute(HabitState state) {
    final today = DateHelper.today();
    final rangeDays = [7, 30, 365, 9999][_rangeIdx];
    final maxDays = rangeDays > 365 ? 365 : rangeDays;

    double totalRate = 0;
    int countDays = 0;
    final dowTotal = List.filled(7, 0);
    final dowComplete = List.filled(7, 0);

    // Single pass: compute overall + day-of-week stats together
    for (int i = 0; i < maxDays; i++) {
      final d = today.subtract(Duration(days: i));
      final h = state.habitsForDate(d);
      if (h.isEmpty) continue;
      final rate = state.completionRate(d);
      totalRate += rate;
      countDays++;
      final dow = d.weekday - 1;
      dowTotal[dow] += h.length;
      for (final habit in h) {
        final e = state.entryFor(habit.id, d);
        if (e != null && e.isCompleted) dowComplete[dow]++;
      }
    }
    _cachedOverall = countDays > 0 ? totalRate / countDays : 0.0;

    final trendDays = [7, 30, 52, 52][_rangeIdx];
    _cachedTrend = List.generate(
      trendDays,
      (i) => FlSpot(
        i.toDouble(),
        state.completionRate(today.subtract(Duration(days: trendDays - 1 - i))),
      ),
    );

    _cachedDow = List.generate(
      7,
      (i) => dowTotal[i] > 0 ? dowComplete[i] / dowTotal[i] : 0.0,
    );

    _cachedHabitRates =
        state.activeHabits.map((h) {
            final entries = state.entriesForHabit(h.id);
            final c = entries.where((e) => e.isCompleted).length;
            return (h, entries.isNotEmpty ? c / entries.length : 0.0);
          }).toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitProvider);
    final profile = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    // Only recompute when state or range actually changes
    final stateId = identityHashCode(state);
    if (_cachedStateIdentity != stateId || _cachedRange != _rangeIdx) {
      _cachedStateIdentity = stateId;
      _cachedRange = _rangeIdx;
      _recompute(state);
    }

    final overall = _cachedOverall;
    final trendData = _cachedTrend;
    final dowData = _cachedDow;
    final habitRates = _cachedHabitRates;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Week')),
              ButtonSegment(value: 1, label: Text('Month')),
              ButtonSegment(value: 2, label: Text('Year')),
              ButtonSegment(value: 3, label: Text('All')),
            ],
            selected: {_rangeIdx},
            onSelectionChanged: (s) => setState(() => _rangeIdx = s.first),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: overall),
                duration: const Duration(milliseconds: 800),
                builder:
                    (_, v, __) => Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: v,
                          strokeWidth: 12,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(v * 100).round()}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Overall', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _mini(context, '${profile.totalHabitsCompleted}', 'Completed'),
              _mini(context, '${profile.longestStreak}', 'Best Streak'),
              _mini(context, '${state.activeHabits.length}', 'Active'),
              _mini(context, 'Lv${profile.level}', profile.levelName),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
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
                minY: 0,
                maxY: 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withAlpha(38),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'By Day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
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
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                ),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dowData[i],
                        color: theme.colorScheme.primary,
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
          if (habitRates.isNotEmpty) ...[
            Text(
              'Best Habits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...habitRates
                .take(3)
                .map(
                  (h) => ListTile(
                    leading: Text(
                      h.$1.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(h.$1.name),
                    trailing: Text(
                      '${(h.$2 * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            Text(
              'Needs Work',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...habitRates.reversed
                .take(3)
                .map(
                  (h) => ListTile(
                    leading: Text(
                      h.$1.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(h.$1.name),
                    trailing: Text(
                      '${(h.$2 * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _mini(BuildContext ctx, String val, String label) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              val,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: Theme.of(ctx).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
