import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/widgets/progress_ring.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _rangeDays = 7;

  // Cached computation results
  Object? _cachedStateId;
  int _cachedRange = -1;
  double _overallRate = 0;
  List<FlSpot> _trendData = [];
  List<MapEntry<HabitModel, double>> _bestHabits = [];
  List<MapEntry<HabitModel, double>> _worstHabits = [];
  List<double> _dayRates = List.filled(7, 0);

  void _recompute(HabitRepositoryAdapter repo) {
    final habits = repo.getActiveHabits();
    _overallRate = 0;
    if (habits.isNotEmpty) {
      _overallRate =
          habits
              .map((h) => repo.getCompletionRate(h.id, days: _rangeDays))
              .reduce((a, b) => a + b) /
          habits.length;
    }

    final now = DateTime.now();
    final trend = <FlSpot>[];
    for (int i = _rangeDays - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final rate = repo.getDailyCompletionRate(date);
      trend.add(FlSpot((_rangeDays - 1 - i).toDouble(), rate * 100));
    }
    _trendData = trend;

    final habitRates =
        habits
            .map(
              (h) =>
                  MapEntry(h, repo.getCompletionRate(h.id, days: _rangeDays)),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    _bestHabits = habitRates.take(3).toList();
    _worstHabits = habitRates.reversed.take(3).toList();

    _dayRates = List.generate(7, (d) {
      int total = 0, completed = 0;
      for (int i = 0; i < _rangeDays; i++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        if (date.weekday == d + 1) {
          final dh = repo.getHabitsForDate(date);
          total += dh.length;
          for (final h in dh) {
            final e = repo.getEntry(h.id, date);
            if (e != null && e.isCompleted) completed++;
          }
        }
      }
      return total > 0 ? completed / total : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(habitRepositoryProvider);
    final profile = ref.watch(profileRepositoryProvider).getProfile();

    // Only recompute when state or range actually changes
    final stateId = identityHashCode(ref.watch(habitsProvider));
    if (_cachedStateId != stateId || _cachedRange != _rangeDays) {
      _cachedStateId = stateId;
      _cachedRange = _rangeDays;
      _recompute(repo);
    }

    final dayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Range toggle
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('Week')),
              ButtonSegment(value: 30, label: Text('Month')),
              ButtonSegment(value: 365, label: Text('Year')),
              ButtonSegment(value: 9999, label: Text('All')),
            ],
            selected: {_rangeDays},
            onSelectionChanged: (v) => setState(() => _rangeDays = v.first),
          ),
          const SizedBox(height: 24),

          // Overall score
          Center(child: ProgressRing(progress: _overallRate, size: 120)),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Overall Score', style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 24),

          // Stats summary
          Row(
            children: [
              _stat(theme, '${profile.totalHabitsCompleted}', 'Completed'),
              _stat(theme, '${profile.longestStreak}', 'Best Streak'),
              _stat(theme, '${profile.totalXP}', 'Total XP'),
            ],
          ),
          const SizedBox(height: 24),

          // Trend chart
          Text(
            'Daily Trend',
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
                    spots: _trendData,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Best habits
          if (_bestHabits.isNotEmpty) ...[
            Text(
              'Best Habits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ..._bestHabits.map(
              (e) => _habitRank(theme, e.key, e.value, Colors.green),
            ),
            const SizedBox(height: 16),
          ],

          // Needs work
          if (_worstHabits.isNotEmpty) ...[
            Text(
              'Needs Work',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ..._worstHabits.map(
              (e) => _habitRank(theme, e.key, e.value, Colors.orange),
            ),
            const SizedBox(height: 24),
          ],

          // Day of week chart
          Text(
            'By Day of Week',
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
                            dayLabels[v.toInt() % 7],
                            style: const TextStyle(fontSize: 11),
                          ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(
                  7,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _dayRates[i] * 100,
                        color: theme.colorScheme.primary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _habitRank(
    ThemeData theme,
    HabitModel habit,
    double rate,
    Color color,
  ) {
    return ListTile(
      leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(habit.name),
      trailing: Text(
        '${(rate * 100).toInt()}%',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
