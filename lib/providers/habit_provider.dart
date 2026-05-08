import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../models/habit_entry.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

const _uuid = Uuid();

class HabitState {
  final List<HabitModel> habits;
  final List<HabitEntry> entries;
  final DateTime selectedDate;
  final bool isLoading;

  // O(1) lookup indexes — built once per state change
  late final Map<String, Map<String, HabitEntry>> _entryIndex;
  late final List<HabitModel> _activeHabits;
  late final Map<String, HabitModel> _habitById;

  HabitState({
    this.habits = const [],
    this.entries = const [],
    DateTime? selectedDate,
    this.isLoading = false,
  }) : selectedDate = selectedDate ?? DateHelper.today() {
    // Build entry index: habitId -> dateKey -> entry
    _entryIndex = {};
    for (final e in entries) {
      final dk = _dateKey(e.date);
      (_entryIndex[e.habitId] ??= {})[dk] = e;
    }
    _activeHabits = habits.where((h) => !h.isArchived).toList();
    _habitById = {for (final h in habits) h.id: h};
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  HabitState copyWith({
    List<HabitModel>? habits,
    List<HabitEntry>? entries,
    DateTime? selectedDate,
    bool? isLoading,
  }) => HabitState(
    habits: habits ?? this.habits,
    entries: entries ?? this.entries,
    selectedDate: selectedDate ?? this.selectedDate,
    isLoading: isLoading ?? this.isLoading,
  );

  List<HabitModel> get activeHabits => _activeHabits;

  HabitModel? habitById(String id) => _habitById[id];

  List<HabitModel> habitsForDate(DateTime date) =>
      _activeHabits.where((h) => h.isScheduledFor(date)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  HabitEntry? entryFor(String habitId, DateTime date) {
    final dk = _dateKey(DateHelper.dateOnly(date));
    return _entryIndex[habitId]?[dk];
  }

  List<HabitEntry> entriesForHabit(String habitId) {
    final map = _entryIndex[habitId];
    if (map == null) return [];
    return map.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double completionRate(DateTime date) {
    final dayHabits = habitsForDate(date);
    if (dayHabits.isEmpty) return 0;
    int completed = 0;
    final dk = _dateKey(DateHelper.dateOnly(date));
    for (final h in dayHabits) {
      final entry = _entryIndex[h.id]?[dk];
      if (entry != null && isEntryComplete(h, entry)) completed++;
    }
    return completed / dayHabits.length;
  }

  static bool isEntryComplete(HabitModel habit, HabitEntry entry) {
    if (entry.isSkipped) return false;
    switch (habit.type) {
      case HabitType.boolean:
        return entry.isCompleted;
      case HabitType.count:
        return entry.countValue >= habit.targetCount;
      case HabitType.duration:
        return entry.durationMinutes >= habit.targetDurationMinutes;
      case HabitType.measurable:
        return entry.measuredValue >= habit.targetValue;
    }
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  HabitNotifier() : super(HabitState(isLoading: true)) {
    _load();
  }

  final _habitBox = Hive.box<HabitModel>('habits');
  final _entryBox = Hive.box<HabitEntry>('habit_entries');

  void _load() {
    state = state.copyWith(
      habits: _habitBox.values.toList(),
      entries: _entryBox.values.toList(),
      isLoading: false,
    );
  }

  void refresh() => _load();

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: DateHelper.dateOnly(date));
  }

  Future<void> addHabit(HabitModel habit) async {
    await _habitBox.put(habit.id, habit);
    _load();
    _checkAchievements();
    NotificationService().scheduleHabitReminders(habit);
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habitBox.put(habit.id, habit);
    _load();
    NotificationService().scheduleHabitReminders(habit);
  }

  Future<void> deleteHabit(String id) async {
    await _habitBox.delete(id);
    final toDelete = _entryBox.values.where((e) => e.habitId == id).toList();
    for (final e in toDelete) {
      await _entryBox.delete(e.key);
    }
    _load();
    NotificationService().cancelHabitReminders(id);
  }

  Future<void> archiveHabit(String id) async {
    final habit = _habitBox.get(id);
    if (habit != null) {
      habit.isArchived = true;
      await habit.save();
      _load();
      NotificationService().cancelHabitReminders(id);
    }
  }

  Future<void> unarchiveHabit(String id) async {
    final habit = _habitBox.get(id);
    if (habit != null) {
      habit.isArchived = false;
      await habit.save();
      _load();
    }
  }

  Future<void> reorderHabits(List<HabitModel> reordered) async {
    for (var i = 0; i < reordered.length; i++) {
      reordered[i].sortOrder = i;
      await reordered[i].save();
    }
    _load();
  }

  Future<bool> toggleBooleanHabit(String habitId, DateTime date) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return false;
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);

    if (existing != null) {
      existing.isCompleted = !existing.isCompleted;
      existing.completedAt = existing.isCompleted ? DateTime.now() : null;
      await existing.save();
      if (existing.isCompleted) _onComplete(habit);
      _load();
      return existing.isCompleted;
    } else {
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await _entryBox.put(entry.id, entry);
      _onComplete(habit);
      _load();
      return true;
    }
  }

  Future<void> incrementCount(String habitId, DateTime date) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return;
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);

    if (existing != null) {
      existing.countValue++;
      if (existing.countValue >= habit.targetCount) {
        existing.isCompleted = true;
        existing.completedAt ??= DateTime.now();
      }
      await existing.save();
    } else {
      final done = 1 >= habit.targetCount;
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        countValue: 1,
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );
      await _entryBox.put(entry.id, entry);
    }
    final e = _findEntry(habitId, d);
    if (e?.isCompleted == true) _onComplete(habit);
    _load();
  }

  Future<void> setCountValue(String habitId, DateTime date, int value) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return;
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);
    final done = value >= habit.targetCount;

    if (existing != null) {
      existing.countValue = value;
      existing.isCompleted = done;
      existing.completedAt =
          done ? (existing.completedAt ?? DateTime.now()) : null;
      await existing.save();
    } else {
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        countValue: value,
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );
      await _entryBox.put(entry.id, entry);
    }
    if (done) _onComplete(habit);
    _load();
  }

  Future<void> setDuration(String habitId, DateTime date, int minutes) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return;
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);
    final done = minutes >= habit.targetDurationMinutes;

    if (existing != null) {
      existing.durationMinutes = minutes;
      existing.isCompleted = done;
      existing.completedAt =
          done ? (existing.completedAt ?? DateTime.now()) : null;
      await existing.save();
    } else {
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        durationMinutes: minutes,
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );
      await _entryBox.put(entry.id, entry);
    }
    if (done) _onComplete(habit);
    _load();
  }

  Future<void> setMeasuredValue(
    String habitId,
    DateTime date,
    double value,
  ) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return;
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);
    final done = value >= habit.targetValue;

    if (existing != null) {
      existing.measuredValue = value;
      existing.isCompleted = done;
      existing.completedAt =
          done ? (existing.completedAt ?? DateTime.now()) : null;
      await existing.save();
    } else {
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        measuredValue: value,
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );
      await _entryBox.put(entry.id, entry);
    }
    if (done) _onComplete(habit);
    _load();
  }

  Future<void> skipHabit(String habitId, DateTime date) async {
    final d = DateHelper.dateOnly(date);
    final existing = _findEntry(habitId, d);
    if (existing != null) {
      existing.isSkipped = true;
      existing.isCompleted = false;
      await existing.save();
    } else {
      final entry = HabitEntry(
        id: _uuid.v4(),
        habitId: habitId,
        date: d,
        isSkipped: true,
      );
      await _entryBox.put(entry.id, entry);
    }
    _load();
  }

  HabitEntry? _findEntry(String habitId, DateTime date) {
    // Use the indexed state for O(1) lookup
    return state.entryFor(habitId, date);
  }

  void _onComplete(HabitModel habit) {
    _updateStreak(habit);
    _addXP(habit);
    _checkAchievements();
  }

  void _updateStreak(HabitModel habit) {
    int streak = 0;
    var date = DateHelper.today();
    int skippedDays = 0;
    // Use state index for O(1) entry lookup — limit to 400 total days examined
    for (int i = 0; i < 400 && skippedDays < 30; i++) {
      if (!habit.isScheduledFor(date)) {
        date = date.subtract(const Duration(days: 1));
        skippedDays++;
        continue;
      }
      skippedDays = 0;
      final entry = state.entryFor(habit.id, date);
      if (entry != null && (entry.isCompleted || entry.isSkipped)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else if (DateHelper.isSameDay(date, DateHelper.today())) {
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    habit.currentStreak = streak;
    if (streak > habit.bestStreak) habit.bestStreak = streak;
    habit.save();
  }

  void _addXP(HabitModel habit) {
    final profileBox = Hive.box<UserProfile>('user_profile');
    final profile = profileBox.get('profile') ?? UserProfile();
    int xp = 10;
    if (habit.type != HabitType.boolean) xp = 15;
    xp += habit.currentStreak * 2;

    final todayHabits = state.habitsForDate(DateHelper.today());
    bool allComplete = todayHabits.isNotEmpty;
    for (final h in todayHabits) {
      final e = state.entryFor(h.id, DateHelper.today());
      if (e == null || (!e.isCompleted && !e.isSkipped)) {
        allComplete = false;
        break;
      }
    }
    if (allComplete && todayHabits.isNotEmpty) xp += 25;

    profile.addXP(xp);
    profile.totalHabitsCompleted++;
    if (habit.currentStreak > profile.longestStreak) {
      profile.longestStreak = habit.currentStreak;
    }
    profileBox.put('profile', profile);
  }

  void _checkAchievements() {
    final achieveBox = Hive.box<Achievement>('achievements');
    final profileBox = Hive.box<UserProfile>('user_profile');
    final profile = profileBox.get('profile') ?? UserProfile();

    if (achieveBox.isEmpty) {
      for (final def in AchievementDefinitions.all) {
        final a = Achievement(
          id: def['id'] as String,
          title: def['title'] as String,
          description: def['description'] as String,
          iconEmoji: def['iconEmoji'] as String,
          type: def['type'] as String,
          requiredValue: def['requiredValue'] as int,
          xpReward: def['xpReward'] as int,
        );
        achieveBox.put(a.id, a);
      }
    }

    for (final achievement in achieveBox.values) {
      if (achievement.isUnlocked) continue;
      int progress = 0;
      switch (achievement.type) {
        case 'streak':
          for (final h in state.habits) {
            if (h.bestStreak > progress) progress = h.bestStreak;
          }
        case 'completion':
          progress = profile.totalHabitsCompleted;
        case 'creation':
          progress = state.habits.length;
        case 'perfect_day':
          progress = state.completionRate(DateHelper.today()) >= 1.0 ? 1 : 0;
        case 'level':
          progress = profile.level;
        default:
          continue;
      }
      achievement.currentProgress = progress;
      if (progress >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        profile.addXP(achievement.xpReward);
        NotificationService().showAchievementUnlocked(
          achievement.title,
          achievement.iconEmoji,
        );
      }
      achievement.save();
    }
    profileBox.put('profile', profile);
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, HabitState>(
  (ref) => HabitNotifier(),
);

/// Alias used by screen files
final habitsProvider = habitProvider;

final selectedDateHabitsProvider = Provider<List<HabitModel>>((ref) {
  final state = ref.watch(habitProvider);
  return state.habitsForDate(state.selectedDate);
});

final todayCompletionProvider = Provider<double>((ref) {
  final state = ref.watch(habitProvider);
  return state.completionRate(state.selectedDate);
});

final userProfileProvider = Provider<UserProfile>((ref) {
  ref.watch(habitProvider);
  final box = Hive.box<UserProfile>('user_profile');
  return box.get('profile') ?? UserProfile();
});

final achievementsProvider = Provider<List<Achievement>>((ref) {
  ref.watch(habitProvider);
  final box = Hive.box<Achievement>('achievements');
  if (box.isEmpty) {
    for (final def in AchievementDefinitions.all) {
      final a = Achievement(
        id: def['id'] as String,
        title: def['title'] as String,
        description: def['description'] as String,
        iconEmoji: def['iconEmoji'] as String,
        type: def['type'] as String,
        requiredValue: def['requiredValue'] as int,
        xpReward: def['xpReward'] as int,
      );
      box.put(a.id, a);
    }
  }
  return box.values.toList();
});

// ─── Additional providers for screen-level access ───

/// Selected date for date strip navigation
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateHelper.today();
});

/// Habits scheduled for the currently selected date
final habitsForDateProvider = Provider<List<HabitModel>>((ref) {
  final state = ref.watch(habitsProvider);
  final date = ref.watch(selectedDateProvider);
  return state.habitsForDate(date);
});

/// Daily progress (completion rate) for selected date
final dailyProgressProvider = Provider<double>((ref) {
  final state = ref.watch(habitsProvider);
  final date = ref.watch(selectedDateProvider);
  return state.completionRate(date);
});

/// Repository-style adapter for screen-level habit access
class HabitRepositoryAdapter {
  final HabitState _state;
  HabitRepositoryAdapter(this._state);

  HabitModel? getHabit(String id) {
    for (final h in _state.habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<HabitModel> getAllHabits() => _state.habits;
  List<HabitModel> getActiveHabits() => _state.activeHabits;
  List<HabitModel> getHabitsForDate(DateTime date) =>
      _state.habitsForDate(date);
  HabitEntry? getEntry(String habitId, DateTime date) =>
      _state.entryFor(habitId, date);
  List<HabitEntry> getEntriesForHabit(String habitId) =>
      _state.entriesForHabit(habitId);
  double getDailyCompletionRate(DateTime date) => _state.completionRate(date);

  double getCompletionRate(String habitId, {int days = 30}) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;
    final now = DateHelper.today();
    int scheduled = 0, completed = 0;
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (!habit.isScheduledFor(date)) continue;
      scheduled++;
      final e = _state.entryFor(habitId, date);
      if (e != null && HabitState.isEntryComplete(habit, e)) completed++;
    }
    return scheduled == 0 ? 0 : completed / scheduled;
  }

  int calculateStreak(String habitId) => getHabit(habitId)?.currentStreak ?? 0;
}

final habitRepositoryProvider = Provider<HabitRepositoryAdapter>((ref) {
  final state = ref.watch(habitsProvider);
  return HabitRepositoryAdapter(state);
});

/// Achievement repository adapter
class AchievementRepoAdapter {
  List<Achievement> getAll() {
    final box = Hive.box<Achievement>('achievements');
    if (box.isEmpty) {
      for (final def in AchievementDefinitions.all) {
        final a = Achievement(
          id: def['id'] as String,
          title: def['title'] as String,
          description: def['description'] as String,
          iconEmoji: def['iconEmoji'] as String,
          type: def['type'] as String,
          requiredValue: def['requiredValue'] as int,
          xpReward: def['xpReward'] as int,
        );
        box.put(a.id, a);
      }
    }
    return box.values.toList();
  }

  Future<void> initializeAchievements() async {
    final box = Hive.box<Achievement>('achievements');
    if (box.isNotEmpty) return;
    for (final def in AchievementDefinitions.all) {
      final a = Achievement(
        id: def['id'] as String,
        title: def['title'] as String,
        description: def['description'] as String,
        iconEmoji: def['iconEmoji'] as String,
        type: def['type'] as String,
        requiredValue: def['requiredValue'] as int,
        xpReward: def['xpReward'] as int,
      );
      await box.put(a.id, a);
    }
  }
}

final achievementRepositoryProvider = Provider<AchievementRepoAdapter>((ref) {
  ref.watch(habitsProvider);
  return AchievementRepoAdapter();
});

/// Habit entries notifier for screen-level entry modifications
class HabitEntriesNotifier extends StateNotifier<Map<String, HabitEntry?>> {
  final Ref _ref;
  HabitEntriesNotifier(this._ref) : super({}) {
    _refresh();
  }

  void _refresh() {
    final habitState = _ref.read(habitsProvider);
    final date = _ref.read(selectedDateProvider);
    final map = <String, HabitEntry?>{};
    for (final habit in habitState.habitsForDate(date)) {
      map[habit.id] = habitState.entryFor(habit.id, date);
    }
    state = map;
  }

  Future<void> toggleBoolean(HabitModel habit) async {
    final date = _ref.read(selectedDateProvider);
    await _ref.read(habitsProvider.notifier).toggleBooleanHabit(habit.id, date);
    _refresh();
  }

  Future<void> incrementCount(HabitModel habit) async {
    final date = _ref.read(selectedDateProvider);
    await _ref.read(habitsProvider.notifier).incrementCount(habit.id, date);
    _refresh();
  }

  Future<void> setCountValue(HabitModel habit, int value) async {
    final date = _ref.read(selectedDateProvider);
    await _ref
        .read(habitsProvider.notifier)
        .setCountValue(habit.id, date, value);
    _refresh();
  }

  /// Alias for [setCountValue]
  Future<void> setCount(HabitModel habit, int value) =>
      setCountValue(habit, value);

  Future<void> setDuration(HabitModel habit, int minutes) async {
    final date = _ref.read(selectedDateProvider);
    await _ref
        .read(habitsProvider.notifier)
        .setDuration(habit.id, date, minutes);
    _refresh();
  }

  Future<void> setMeasuredValue(HabitModel habit, double value) async {
    final date = _ref.read(selectedDateProvider);
    await _ref
        .read(habitsProvider.notifier)
        .setMeasuredValue(habit.id, date, value);
    _refresh();
  }

  /// Alias for [setMeasuredValue]
  Future<void> setMeasurable(HabitModel habit, double value) =>
      setMeasuredValue(habit, value);

  Future<void> skipHabit(HabitModel habit) async {
    final date = _ref.read(selectedDateProvider);
    await _ref.read(habitsProvider.notifier).skipHabit(habit.id, date);
    _refresh();
  }
}

final habitEntriesProvider =
    StateNotifierProvider<HabitEntriesNotifier, Map<String, HabitEntry?>>((
      ref,
    ) {
      final notifier = HabitEntriesNotifier(ref);
      ref.listen(habitsProvider, (_, __) => notifier._refresh());
      ref.listen(selectedDateProvider, (_, __) => notifier._refresh());
      return notifier;
    });
