import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/habit_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Pre-computed rate cache for the visible month
  Object? _cachedStateId;
  DateTime? _cachedMonth;
  final Map<String, double> _rateCache = {};

  static const _rateColors = [
    Colors.green, // >= 1.0
    Colors.lightGreen, // >= 0.75
    Color(0xFFF9A825), // >= 0.50 (yellow.shade700)
    Colors.orange, // >= 0.25
    Colors.red, // > 0
  ];

  Color _getColorForRate(double rate) {
    if (rate >= 1.0) return _rateColors[0];
    if (rate >= 0.75) return _rateColors[1];
    if (rate >= 0.50) return _rateColors[2];
    if (rate >= 0.25) return _rateColors[3];
    if (rate > 0) return _rateColors[4];
    return Colors.grey.shade300;
  }

  double _cachedRate(DateTime day) {
    final key = '${day.year}-${day.month}-${day.day}';
    return _rateCache[key] ?? 0.0;
  }

  void _buildRateCache(dynamic repo) {
    _rateCache.clear();
    final first = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    // Also cover a few days before/after for calendar overflow
    final start = first.subtract(const Duration(days: 7));
    final end = last.add(const Duration(days: 7));
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = '${d.year}-${d.month}-${d.day}';
      _rateCache[key] = repo.getDailyCompletionRate(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(habitRepositoryProvider);

    // Only rebuild rate cache when state or month changes
    final stateId = identityHashCode(ref.watch(habitsProvider));
    final monthKey = DateTime(_focusedDay.year, _focusedDay.month);
    if (_cachedStateId != stateId || _cachedMonth != monthKey) {
      _cachedStateId = stateId;
      _cachedMonth = monthKey;
      _buildRateCache(repo);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayDetails(context, selectedDay, repo);
            },
            onFormatChanged:
                (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Invalidate cache when month changes
              _cachedMonth = null;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final rate = _cachedRate(day);
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        rate > 0 ? _getColorForRate(rate).withAlpha(77) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('${day.day}')),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final rate = _cachedRate(day);
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getColorForRate(rate).withAlpha(77),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legend('100%', Colors.green),
                _legend('75%+', Colors.lightGreen),
                _legend('50%+', Colors.yellow.shade700),
                _legend('25%+', Colors.orange),
                _legend('<25%', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withAlpha(77),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _showDayDetails(BuildContext context, DateTime day, dynamic repo) {
    final habits = repo.getHabitsForDate(day);
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.day}/${day.month}/${day.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (habits.isEmpty)
                  const Text('No habits scheduled for this day')
                else
                  ...habits.map((h) {
                    final entry = repo.getEntry(h.id, day);
                    return ListTile(
                      leading: Text(
                        h.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(h.name),
                      trailing: Icon(
                        entry?.isCompleted == true
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color:
                            entry?.isCompleted == true
                                ? Colors.green
                                : Colors.grey,
                      ),
                      onTap: () {
                        // Backfill: allow completing past habits (up to 7 days)
                        final diff = DateTime.now().difference(day).inDays;
                        if (diff >= 0 && diff <= 7) {
                          repo.createOrUpdateEntry(
                            habitId: h.id,
                            date: day,
                            isCompleted: !(entry?.isCompleted ?? false),
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
