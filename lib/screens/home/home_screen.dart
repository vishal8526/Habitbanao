import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/widgets/habit_tile.dart';
import '../home/widgets/date_strip.dart';
import '../home/widgets/progress_ring.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;
  bool _celebrationShown = false;

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileRepositoryProvider).getProfile();
    final habits = ref.watch(habitsForDateProvider);
    final progress = ref.watch(dailyProgressProvider);
    final entries = ref.watch(habitEntriesProvider);

    // Check for confetti
    if (progress >= 1.0 && habits.isNotEmpty && !_celebrationShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
        _celebrationShown = true;
      });
    }
    if (progress < 1.0) _celebrationShown = false;

    // Group by time of day
    final groups = <TimeOfDayCategory, List<HabitModel>>{};
    for (final h in habits) {
      groups.putIfAbsent(h.timeOfDay, () => []).add(h);
    }
    final orderedKeys =
        [
          TimeOfDayCategory.morning,
          TimeOfDayCategory.afternoon,
          TimeOfDayCategory.evening,
          TimeOfDayCategory.anytime,
        ].where((k) => groups.containsKey(k)).toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            ref.read(habitsProvider.notifier).refresh();
            ref.invalidate(dailyProgressProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: Text(
                  'HabitForge',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Text('😊', style: TextStyle(fontSize: 22)),
                    onPressed: () => context.push('/mood'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    onPressed: () => context.push('/journal'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.timer_outlined),
                    onPressed: () => context.push('/focus'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined),
                    onPressed: () => context.push('/achievements'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '${_greeting()}, ${profile.name}! 👋',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.getQuoteForToday(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ProgressRing(progress: progress, size: 80),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(progress * 100).toInt()}% Complete',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildStreakRow(habits, ref),
                                const SizedBox(height: 4),
                                Text(
                                  'Level ${profile.level} • ${AppConstants.levelNames[profile.level] ?? ""}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: DateStrip()),
              if (habits.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'No habits for today',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => context.push('/create-habit'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first habit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ...orderedKeys.expand(
                (key) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        _timeLabel(key),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final habit = groups[key]![index];
                      final entry = entries[habit.id];
                      return Dismissible(
                        key: ValueKey(habit.id),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(habitEntriesProvider.notifier)
                                .toggleBoolean(habit);
                            return false;
                          } else {
                            ref
                                .read(habitEntriesProvider.notifier)
                                .skipHabit(habit);
                            return false;
                          }
                        },
                        background: Container(
                          color: Colors.green.withAlpha(51),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                        secondaryBackground: Container(
                          color: Colors.orange.withAlpha(51),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.skip_next,
                            color: Colors.orange,
                          ),
                        ),
                        child: HabitTile(habit: habit, entry: entry),
                      );
                    }, childCount: groups[key]!.length),
                  ),
                ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakRow(List<HabitModel> habits, WidgetRef ref) {
    final maxStreak =
        habits.isEmpty
            ? 0
            : habits
                .map((h) => h.currentStreak)
                .reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          '$maxStreak day streak',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _timeLabel(TimeOfDayCategory cat) {
    switch (cat) {
      case TimeOfDayCategory.morning:
        return '🌅 Morning';
      case TimeOfDayCategory.afternoon:
        return '☀️ Afternoon';
      case TimeOfDayCategory.evening:
        return '🌙 Evening';
      case TimeOfDayCategory.anytime:
        return '⭐ Anytime';
    }
  }
}
