import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../utils/helpers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitProvider);
    final theme = Theme.of(context);
    final days = DateHelper.daysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final fw = days.first.weekday;
    final List<DateTime?> padded = [
      ...List<DateTime?>.filled(fw - 1, null),
      ...days,
    ];

    // Pre-compute all completion rates for the month — O(days) with indexed state
    final rateCache = <int, double>{};
    for (final d in days) {
      rateCache[d.day] = state.completionRate(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed:
                () => setState(
                  () =>
                      _currentMonth = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                      ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      () => setState(
                        () =>
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month - 1,
                            ),
                      ),
                ),
                Text(
                  '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      () => setState(
                        () =>
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month + 1,
                            ),
                      ),
                ),
              ],
            ),
          ),
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children:
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: padded.length,
              itemBuilder: (_, i) {
                final date = padded[i];
                if (date == null) return const SizedBox();

                final rate = rateCache[date.day] ?? 0.0;
                final isToday = DateHelper.isSameDay(date, DateHelper.today());
                final isFuture = date.isAfter(DateHelper.today());
                final color = _rateColor(rate, isFuture);

                return GestureDetector(
                  onTap: () => _showDaySheet(context, ref, date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isToday
                              ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : null,
                          color:
                              isFuture
                                  ? theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4)
                                  : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem('100%', Colors.green),
                _legendItem('75%+', Colors.lightGreen),
                _legendItem('50%+', Colors.yellow.shade700),
                _legendItem('25%+', Colors.orange),
                _legendItem('<25%', Colors.red.shade300),
                _legendItem('0%', Colors.grey.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pre-computed colors to avoid creating new Color objects per cell
  static final _rateColors = <Color>[
    Colors.grey.withAlpha(38), // 0%
    Colors.red.withAlpha(77), // <25%
    Colors.orange.withAlpha(102), // 25%+
    Colors.yellow.withAlpha(128), // 50%+
    Colors.lightGreen.withAlpha(128), // 75%+
    Colors.green.withAlpha(153), // 100%
  ];

  Color _rateColor(double rate, bool isFuture) {
    if (isFuture) return Colors.transparent;
    if (rate >= 1.0) return _rateColors[5];
    if (rate >= 0.75) return _rateColors[4];
    if (rate >= 0.5) return _rateColors[3];
    if (rate >= 0.25) return _rateColors[2];
    if (rate > 0) return _rateColors[1];
    return _rateColors[0];
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  String _monthName(int m) =>
      [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][m];

  void _showDaySheet(BuildContext context, WidgetRef ref, DateTime date) {
    final state = ref.read(habitProvider);
    final habits = state.habitsForDate(date);
    final canBackfill =
        DateHelper.today().difference(date).inDays <= 7 &&
        !date.isAfter(DateHelper.today());

    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateHelper.formatDate(date),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${(state.completionRate(date) * 100).round()}% completed',
                ),
                const Divider(),
                if (habits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No habits scheduled for this day.'),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        habits.map((h) {
                          final entry = state.entryFor(h.id, date);
                          final done = entry?.isCompleted ?? false;
                          return ListTile(
                            leading: Text(
                              h.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(h.name),
                            trailing:
                                canBackfill && !done
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(habitProvider.notifier)
                                            .toggleBooleanHabit(h.id, date);
                                        Navigator.pop(context);
                                      },
                                    )
                                    : Icon(
                                      done
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: done ? Colors.green : null,
                                    ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }
}
