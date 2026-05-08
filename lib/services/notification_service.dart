import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/habit_model.dart';
import '../models/habit_entry.dart';

/// Notification ID ranges:
/// 1000-1999: Per-habit reminders (habitId.hashCode % 1000 + reminderIndex * 1000)
/// 2000: Morning summary
/// 2001: Evening summary
/// 2002: Streak at risk
/// 2003: Weekly report
/// 2004: Inactivity reminder
/// 3000+: Achievement unlocked

class NotificationHealthStatus {
  final bool initialized;
  final bool? notificationsEnabled;
  final int pendingCount;
  final bool settingsBoxOpen;
  final bool habitsBoxOpen;
  final bool entriesBoxOpen;
  final DateTime checkedAt;

  const NotificationHealthStatus({
    required this.initialized,
    required this.notificationsEnabled,
    required this.pendingCount,
    required this.settingsBoxOpen,
    required this.habitsBoxOpen,
    required this.entriesBoxOpen,
    required this.checkedAt,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initializing;

  // ---------- INITIALIZATION ----------

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = () async {
      tz_data.initializeTimeZones();
      try {
        final tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initialized = true;
    }();

    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _ensureBoxOpen<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    // Handle actionable notification actions
    if (response.actionId == 'mark_done') {
      await _markHabitDone(payload);
    }
    // 'snooze' action is handled by scheduling a new notification
    if (response.actionId == 'snooze') {
      await _snoozeReminder(payload);
    }
  }

  Future<void> _markHabitDone(String habitId) async {
    try {
      await _ensureBoxOpen<HabitModel>('habits');
      await _ensureBoxOpen<HabitEntry>('habit_entries');
      final habitBox = Hive.box<HabitModel>('habits');
      final entryBox = Hive.box<HabitEntry>('habit_entries');
      final habit = habitBox.get(habitId);
      if (habit == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final deterministicId = '${habitId}_$dateKey';

      // Check if entry exists
      HabitEntry? existing = entryBox.get(deterministicId);
      if (existing == null) {
        for (final e in entryBox.values) {
          if (e.habitId == habitId &&
              e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day) {
            existing = e;
            break;
          }
        }
      }

      if (existing != null) {
        existing.isCompleted = true;
        existing.completedAt = DateTime.now();
        await existing.save();
      } else {
        final entry = HabitEntry(
          id: deterministicId,
          habitId: habitId,
          date: today,
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await entryBox.put(entry.id, entry);
      }
    } catch (_) {}
  }

  Future<void> _snoozeReminder(String habitId) async {
    try {
      await _ensureBoxOpen<HabitModel>('habits');
      final habitBox = Hive.box<HabitModel>('habits');
      final habit = habitBox.get(habitId);
      if (habit == null) return;

      // Schedule a notification 15 minutes from now
      final snoozeTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(minutes: 15));
      await _scheduleNotification(
        id: habitId.hashCode % 900 + 100,
        title: '${habit.emoji} Reminder: ${habit.name}',
        body: 'Snoozed reminder — time to complete this habit!',
        scheduledDate: snoozeTime,
        payload: habitId,
      );
    } catch (_) {}
  }

  // ---------- NOTIFICATION CHANNEL ----------

  static const _channelId = 'habitforge_reminders';
  static const _channelName = 'Habit Reminders';
  static const _channelDesc = 'Reminders for your habits';

  NotificationDetails get _notificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: const [
        AndroidNotificationAction(
          'mark_done',
          'Mark Done',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 15m',
          showsUserInterface: false,
        ),
      ],
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  NotificationDetails get _simpleDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'habitforge_general',
      'HabitForge',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ---------- SCHEDULE HELPERS ----------

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    await initialize();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    NotificationDetails? details,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details ?? _simpleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Move to the correct weekday
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _simpleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ---------- PER-HABIT REMINDERS ----------

  /// Schedule all reminders for a single habit.
  /// Called after creating/editing a habit.
  Future<void> scheduleHabitReminders(HabitModel habit) async {
    await initialize();
    // Cancel existing reminders for this habit first
    await cancelHabitReminders(habit.id);

    if (habit.isArchived || habit.reminderTimes.isEmpty) return;

    for (int i = 0; i < habit.reminderTimes.length; i++) {
      final parts = habit.reminderTimes[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final notifId = _habitReminderId(habit.id, i);

      await _scheduleDailyNotification(
        id: notifId,
        title: '${habit.emoji} Time for: ${habit.name}',
        body: _habitReminderBody(habit),
        hour: hour,
        minute: minute,
        payload: habit.id,
        details: _notificationDetails,
      );
    }
  }

  String _habitReminderBody(HabitModel habit) {
    switch (habit.type) {
      case HabitType.boolean:
        return 'Tap to mark as done! 🔥 Streak: ${habit.currentStreak} days';
      case HabitType.count:
        return 'Target: ${habit.targetCount} ${habit.unit}';
      case HabitType.duration:
        return 'Target: ${habit.targetDurationMinutes} minutes';
      case HabitType.measurable:
        return 'Target: ${habit.targetValue} ${habit.unit}';
    }
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  int _habitReminderId(String habitId, int index) {
    return (_stableHash(habitId) % 900 + 1000) + index;
  }

  /// Cancel all reminders for a specific habit
  Future<void> cancelHabitReminders(String habitId) async {
    await initialize();
    // Cancel up to 10 possible reminders per habit
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(_habitReminderId(habitId, i));
    }
  }

  /// Reschedule reminders for ALL active habits.
  /// Called on app startup and after bulk changes.
  Future<void> rescheduleAllHabitReminders() async {
    await initialize();
    try {
      await _ensureBoxOpen<HabitModel>('habits');
      final habitBox = Hive.box<HabitModel>('habits');
      for (final habit in habitBox.values) {
        if (!habit.isArchived) {
          await scheduleHabitReminders(habit);
        }
      }
    } catch (_) {}
  }

  // ---------- MORNING SUMMARY ----------

  Future<void> scheduleMorningSummary({int hour = 8, int minute = 0}) async {
    await initialize();
    try {
      await _ensureBoxOpen<HabitModel>('habits');
      final habitBox = Hive.box<HabitModel>('habits');
      final today = DateTime.now();
      final count =
          habitBox.values
              .where((h) => !h.isArchived && h.isScheduledFor(today))
              .length;

      await _scheduleDailyNotification(
        id: 2000,
        title: '☀️ Good Morning!',
        body:
            'You have $count habit${count == 1 ? '' : 's'} to complete today. Let\'s make it a great day!',
        hour: hour,
        minute: minute,
      );
    } catch (_) {}
  }

  Future<void> cancelMorningSummary() async {
    await initialize();
    await _plugin.cancel(2000);
  }

  // ---------- EVENING SUMMARY ----------

  Future<void> scheduleEveningSummary({int hour = 21, int minute = 0}) async {
    await initialize();
    await _scheduleDailyNotification(
      id: 2001,
      title: '🌙 Daily Summary',
      body: 'Check your progress for today — keep your streaks alive!',
      hour: hour,
      minute: minute,
    );
  }

  Future<void> cancelEveningSummary() async {
    await initialize();
    await _plugin.cancel(2001);
  }

  // ---------- STREAK AT RISK ----------

  /// Schedule a "streak at risk" notification 2 hours before midnight.
  Future<void> scheduleStreakAtRisk() async {
    await initialize();
    try {
      await _ensureBoxOpen<HabitModel>('habits');
      await _ensureBoxOpen<HabitEntry>('habit_entries');
      final habitBox = Hive.box<HabitModel>('habits');
      final entryBox = Hive.box<HabitEntry>('habit_entries');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      bool hasIncomplete = false;
      for (final habit in habitBox.values) {
        if (habit.isArchived || !habit.isScheduledFor(today)) continue;
        if (habit.currentStreak <= 0) continue;

        bool found = false;
        for (final e in entryBox.values) {
          if (e.habitId == habit.id &&
              e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day &&
              e.isCompleted) {
            found = true;
            break;
          }
        }
        if (!found) {
          hasIncomplete = true;
          break;
        }
      }

      if (hasIncomplete) {
        await _scheduleDailyNotification(
          id: 2002,
          title: '🔥 Streak at Risk!',
          body:
              'You have incomplete habits with active streaks. Don\'t break the chain!',
          hour: 22,
          minute: 0,
          details: _notificationDetails,
        );
      } else {
        await _plugin.cancel(2002);
      }
    } catch (_) {}
  }

  // ---------- WEEKLY REPORT ----------

  Future<void> scheduleWeeklyReport() async {
    await initialize();
    await _scheduleWeeklyNotification(
      id: 2003,
      title: '📊 Weekly Report',
      body: 'Your weekly habit report is ready! See how you did this week.',
      weekday: DateTime.sunday,
      hour: 10,
      minute: 0,
    );
  }

  Future<void> cancelWeeklyReport() async {
    await initialize();
    await _plugin.cancel(2003);
  }

  // ---------- INACTIVITY REMINDER ----------

  /// Schedule a reminder for 2 days from now.
  /// Should be called on every app open to push it forward.
  Future<void> scheduleInactivityReminder() async {
    await initialize();
    await _plugin.cancel(2004);
    final inactiveDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 2));
    await _plugin.zonedSchedule(
      2004,
      '👋 We miss you!',
      'You haven\'t logged any habits in 2 days. Your streaks need you!',
      inactiveDate,
      _simpleDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ---------- ACHIEVEMENT UNLOCKED ----------

  Future<void> showAchievementUnlocked(String title, String emoji) async {
    await initialize();
    await _plugin.show(
      3000 + title.hashCode.abs() % 1000,
      '$emoji Achievement Unlocked!',
      title,
      _simpleDetails,
    );
  }

  // ---------- FOCUS TIMER COMPLETE ----------

  Future<void> showTimerComplete(String? habitName) async {
    await initialize();
    await _plugin.show(
      4000,
      '⏰ Timer Complete!',
      habitName != null
          ? 'Great focus session on "$habitName"!'
          : 'Great focus session! Take a break.',
      _simpleDetails,
    );
  }

  // ---------- CANCEL ALL ----------

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  // ---------- SETUP FROM SETTINGS ----------

  /// Read settings from Hive and schedule/cancel accordingly.
  Future<void> syncWithSettings() async {
    await initialize();
    await _ensureBoxOpen<dynamic>('settings');
    final box = Hive.box('settings');

    // Morning summary
    final morningEnabled =
        box.get('morning_reminder', defaultValue: true) as bool;
    if (morningEnabled) {
      final hour = box.get('morning_reminder_hour', defaultValue: 8) as int;
      final minute = box.get('morning_reminder_minute', defaultValue: 0) as int;
      await scheduleMorningSummary(hour: hour, minute: minute);
    } else {
      await cancelMorningSummary();
    }

    // Evening summary
    final eveningEnabled =
        box.get('evening_reminder', defaultValue: true) as bool;
    if (eveningEnabled) {
      final hour = box.get('evening_reminder_hour', defaultValue: 21) as int;
      final minute = box.get('evening_reminder_minute', defaultValue: 0) as int;
      await scheduleEveningSummary(hour: hour, minute: minute);
    } else {
      await cancelEveningSummary();
    }

    // Streak at risk
    final streakEnabled = box.get('streak_alert', defaultValue: true) as bool;
    if (streakEnabled) {
      await scheduleStreakAtRisk();
    } else {
      await _plugin.cancel(2002);
    }

    // Weekly report
    final weeklyEnabled = box.get('weekly_report', defaultValue: true) as bool;
    if (weeklyEnabled) {
      await scheduleWeeklyReport();
    } else {
      await cancelWeeklyReport();
    }

    // Inactivity
    await scheduleInactivityReminder();

    // Per-habit reminders
    await rescheduleAllHabitReminders();
  }

  // ---------- HEALTH CHECK ----------

  Future<NotificationHealthStatus> getHealthStatus() async {
    await initialize();

    bool? notificationsEnabled;
    try {
      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      notificationsEnabled = await androidPlugin?.areNotificationsEnabled();
    } catch (_) {}

    int pendingCount = 0;
    try {
      pendingCount = (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {}

    return NotificationHealthStatus(
      initialized: _initialized,
      notificationsEnabled: notificationsEnabled,
      pendingCount: pendingCount,
      settingsBoxOpen: Hive.isBoxOpen('settings'),
      habitsBoxOpen: Hive.isBoxOpen('habits'),
      entriesBoxOpen: Hive.isBoxOpen('habit_entries'),
      checkedAt: DateTime.now(),
    );
  }

  Future<NotificationHealthStatus> repairNotifications() async {
    await initialize();

    await cancelAll();
    await syncWithSettings();

    return getHealthStatus();
  }
}
