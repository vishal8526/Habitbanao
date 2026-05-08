import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../models/habit_model.dart';
import '../models/habit_entry.dart';
import '../providers/habit_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;
  bool _confettiShown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final profile = ref.watch(userProfileProvider);
    final completion = ref.watch(todayCompletionProvider);
    final selectedDate = habitState.selectedDate;
    final habits = habitState.habitsForDate(selectedDate);
    final theme = Theme.of(context);
    final today = DateHelper.today();

    if (completion >= 1.0 && habits.isNotEmpty && !_confettiShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
        _confettiShown = true;
      });
    }
    if (completion < 1.0) _confettiShown = false;

    final grouped = <TimeOfDayCategory, List<HabitModel>>{};
    for (final h in habits) {
      grouped.putIfAbsent(h.timeOfDay, () => []).add(h);
    }
    final orderedGroups =
        [
          TimeOfDayCategory.morning,
          TimeOfDayCategory.afternoon,
          TimeOfDayCategory.evening,
          TimeOfDayCategory.anytime,
        ].where((t) => grouped.containsKey(t)).toList();

    final quote = AppConstants.getQuoteForDay(DateHelper.dayOfYear(today));
    final bestStreak = habits.fold(
      0,
      (int maxStreak, habit) =>
          habit.currentStreak > maxStreak ? habit.currentStreak : maxStreak,
    );
    final dateItems = List.generate(
      15,
      (index) => today.add(Duration(days: index - 7)),
    );
    final dayCompletionByKey = <String, double>{
      for (final date in dateItems)
        '${date.year}-${date.month}-${date.day}': habitState.completionRate(
          date,
        ),
    };

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('HabitBanao'),
            actions: [
              IconButton(
                icon: const Text('😊', style: TextStyle(fontSize: 22)),
                tooltip: 'Mood',
                onPressed: () => context.push('/mood'),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Journal',
                onPressed: () => context.push('/journal'),
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: 'Focus Timer',
                onPressed: () => context.push('/focus-timer'),
              ),
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined),
                tooltip: 'Achievements',
                onPressed: () => context.push('/achievements'),
              ),
            ],
          ),
          body:
              habits.isEmpty
                  ? _buildEmptyState(context)
                  : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(habitProvider),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateHelper.greeting()}, ${profile.name}!',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  quote,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _ProgressRing(value: completion, size: 80),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${(completion * 100).round()}% Complete',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                '🔥',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Best: $bestStreak days',
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Lv${profile.level} ${profile.levelName} • ${profile.totalXP} XP',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 72,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemExtent: 60,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemCount: 15,
                              itemBuilder: (context, i) {
                                final date = dateItems[i];
                                final isSel = DateHelper.isSameDay(
                                  date,
                                  selectedDate,
                                );
                                final isToday = DateHelper.isSameDay(
                                  date,
                                  today,
                                );
                                final dayComp =
                                    dayCompletionByKey['${date.year}-${date.month}-${date.day}'] ??
                                    0;
                                return GestureDetector(
                                  onTap:
                                      () => ref
                                          .read(habitProvider.notifier)
                                          .selectDate(date),
                                  child: Container(
                                    width: 52,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSel
                                              ? theme.colorScheme.primary
                                              : (isToday
                                                  ? theme
                                                      .colorScheme
                                                      .primaryContainer
                                                  : null),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          isToday && !isSel
                                              ? Border.all(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 2,
                                              )
                                              : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateHelper.dayName(date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                isSel
                                                    ? theme
                                                        .colorScheme
                                                        .onPrimary
                                                    : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isSel
                                                    ? theme
                                                        .colorScheme
                                                        .onPrimary
                                                    : null,
                                          ),
                                        ),
                                        if (dayComp > 0 && !date.isAfter(today))
                                          Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  dayComp >= 1.0
                                                      ? Colors.green
                                                      : (isSel
                                                          ? theme
                                                              .colorScheme
                                                              .onPrimary
                                                              .withAlpha(179)
                                                          : Colors.orange),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        for (final group in orderedGroups) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                _groupTitle(group),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final habit = grouped[group]![i];
                              final entry = habitState.entryFor(
                                habit.id,
                                selectedDate,
                              );
                              return RepaintBoundary(
                                child: _HabitTile(
                                  habit: habit,
                                  entry: entry,
                                  date: selectedDate,
                                  onTap: () => _handleTap(habit, selectedDate),
                                  onLongPress:
                                      () =>
                                          _handleLongPress(habit, selectedDate),
                                ),
                              );
                            }, childCount: grouped[group]!.length),
                          ),
                        ],
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 80),
                        ),
                      ],
                    ),
                  ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              theme.colorScheme.tertiary,
              Colors.amber,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text('No habits yet!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create your first habit to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/create-habit'),
            icon: const Icon(Icons.add),
            label: const Text('Create Habit'),
          ),
        ],
      ),
    );
  }

  String _groupTitle(TimeOfDayCategory c) {
    switch (c) {
      case TimeOfDayCategory.morning:
        return '🌅 Morning';
      case TimeOfDayCategory.afternoon:
        return '☀️ Afternoon';
      case TimeOfDayCategory.evening:
        return '🌙 Evening';
      case TimeOfDayCategory.anytime:
        return '⏰ Anytime';
    }
  }

  void _handleTap(HabitModel habit, DateTime date) {
    switch (habit.type) {
      case HabitType.boolean:
        HapticFeedback.mediumImpact();
        ref.read(habitProvider.notifier).toggleBooleanHabit(habit.id, date);
      case HabitType.count:
        HapticFeedback.lightImpact();
        ref.read(habitProvider.notifier).incrementCount(habit.id, date);
      case HabitType.duration:
        _showDurationInput(habit, date);
      case HabitType.measurable:
        _showMeasuredInput(habit, date);
    }
  }

  void _handleLongPress(HabitModel habit, DateTime date) {
    if (habit.type == HabitType.count) {
      _showCountInput(habit, date);
    } else {
      context.push('/habit/${habit.id}');
    }
  }

  void _showCountInput(HabitModel habit, DateTime date) {
    final ctrl = TextEditingController();
    final entry = ref.read(habitProvider).entryFor(habit.id, date);
    if (entry != null) ctrl.text = entry.countValue.toString();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${habit.emoji} ${habit.name}'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Count',
                suffixText: '/ ${habit.targetCount} ${habit.unit}',
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(habitProvider.notifier)
                      .setCountValue(
                        habit.id,
                        date,
                        int.tryParse(ctrl.text) ?? 0,
                      );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showDurationInput(HabitModel habit, DateTime date) {
    final ctrl = TextEditingController();
    final entry = ref.read(habitProvider).entryFor(habit.id, date);
    if (entry != null) ctrl.text = entry.durationMinutes.toString();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${habit.emoji} ${habit.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Minutes',
                    suffixText: '/ ${habit.targetDurationMinutes} min',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.push('/focus-timer');
                  },
                  child: const Text('Use Focus Timer'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(habitProvider.notifier)
                      .setDuration(
                        habit.id,
                        date,
                        int.tryParse(ctrl.text) ?? 0,
                      );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showMeasuredInput(HabitModel habit, DateTime date) {
    final ctrl = TextEditingController();
    final entry = ref.read(habitProvider).entryFor(habit.id, date);
    if (entry != null) ctrl.text = entry.measuredValue.toString();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${habit.emoji} ${habit.name}'),
            content: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Value',
                suffixText: '/ ${habit.targetValue} ${habit.unit}',
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref
                      .read(habitProvider.notifier)
                      .setMeasuredValue(
                        habit.id,
                        date,
                        double.tryParse(ctrl.text) ?? 0,
                      );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  const _ProgressRing({required this.value, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              value >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
          ),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final HabitModel habit;
  final HabitEntry? entry;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _HabitTile({
    required this.habit,
    this.entry,
    required this.date,
    required this.onTap,
    required this.onLongPress,
  });

  bool get _isComplete =>
      entry != null && HabitState.isEntryComplete(habit, entry!);

  double get _progress {
    if (entry == null) return 0;
    switch (habit.type) {
      case HabitType.boolean:
        return entry!.isCompleted ? 1.0 : 0.0;
      case HabitType.count:
        return habit.targetCount > 0
            ? (entry!.countValue / habit.targetCount).clamp(0.0, 1.0)
            : 0;
      case HabitType.duration:
        return habit.targetDurationMinutes > 0
            ? (entry!.durationMinutes / habit.targetDurationMinutes).clamp(
              0.0,
              1.0,
            )
            : 0;
      case HabitType.measurable:
        return habit.targetValue > 0
            ? (entry!.measuredValue / habit.targetValue).clamp(0.0, 1.0)
            : 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);
    final complete = _isComplete;
    final skipped = entry?.isSkipped ?? false;

    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed:
                (_) =>
                    ref.read(habitProvider.notifier).skipHabit(habit.id, date),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.skip_next,
            label: 'Skip',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 0,
        color:
            complete
                ? color.withAlpha(31)
                : (skipped
                    ? theme.colorScheme.surfaceContainerHighest.withAlpha(128)
                    : null),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                complete
                    ? color.withAlpha(77)
                    : theme.colorScheme.outlineVariant.withAlpha(77),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      if (habit.type != HabitType.boolean)
                        CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 3,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      Center(
                        child: Text(
                          skipped ? '⏭️' : habit.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              complete ? TextDecoration.lineThrough : null,
                          color:
                              skipped
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                        ),
                      ),
                      _progressText(theme),
                    ],
                  ),
                ),
                if (habit.currentStreak > 0) ...[
                  Text(
                    '🔥${habit.currentStreak}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete ? color : Colors.transparent,
                    border: Border.all(
                      color: complete ? color : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child:
                      complete
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressText(ThemeData theme) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    switch (habit.type) {
      case HabitType.boolean:
        return const SizedBox.shrink();
      case HabitType.count:
        return Text(
          '${entry?.countValue ?? 0} / ${habit.targetCount} ${habit.unit}',
          style: style,
        );
      case HabitType.duration:
        return Text(
          '${DurationHelper.format(entry?.durationMinutes ?? 0)} / ${DurationHelper.format(habit.targetDurationMinutes)}',
          style: style,
        );
      case HabitType.measurable:
        return Text(
          '${entry?.measuredValue ?? 0} / ${habit.targetValue} ${habit.unit}',
          style: style,
        );
    }
  }
}
