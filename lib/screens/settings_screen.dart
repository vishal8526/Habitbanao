import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/habit_model.dart';
import '../models/habit_entry.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
  }

  bool _getBool(String key, [bool def = false]) =>
      _settingsBox.get(key, defaultValue: def) as bool;
  int _getInt(String key, [int def = 0]) =>
      _settingsBox.get(key, defaultValue: def) as int;

  Future<void> _toggleSetting(String key, bool value) async {
    await _settingsBox.put(key, value);
    await NotificationService().syncWithSettings();
    setState(() {});
  }

  Future<void> _pickTime(
    BuildContext ctx,
    String hourKey,
    String minKey,
  ) async {
    final h = _getInt(hourKey, hourKey.contains('morning') ? 8 : 21);
    final m = _getInt(minKey, 0);
    final picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (picked != null) {
      await _settingsBox.put(hourKey, picked.hour);
      await _settingsBox.put(minKey, picked.minute);
      await NotificationService().syncWithSettings();
      setState(() {});
    }
  }

  Future<void> _runNotificationHealthCheck(BuildContext ctx) async {
    final messenger = ScaffoldMessenger.of(ctx);
    messenger.showSnackBar(
      const SnackBar(content: Text('Running notification health check...')),
    );

    try {
      final status = await NotificationService().getHealthStatus();
      if (!ctx.mounted) return;

      final enabledText =
          status.notificationsEnabled == null
              ? 'Unknown (platform did not report)'
              : (status.notificationsEnabled! ? 'Enabled' : 'Disabled');

      Future<void> runRepair() async {
        messenger.showSnackBar(
          const SnackBar(content: Text('Repairing notifications...')),
        );

        try {
          final repaired = await NotificationService().repairNotifications();
          if (!ctx.mounted) return;

          final repairedEnabledText =
              repaired.notificationsEnabled == null
                  ? 'Unknown (platform did not report)'
                  : (repaired.notificationsEnabled! ? 'Enabled' : 'Disabled');

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Repair complete. Pending notifications: ${repaired.pendingCount}',
              ),
            ),
          );

          await showDialog(
            context: ctx,
            builder:
                (repairDialogCtx) => AlertDialog(
                  title: const Text('Notification Repair Result'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plugin initialized: ${repaired.initialized}'),
                      Text('Permission state: $repairedEnabledText'),
                      Text('Pending notifications: ${repaired.pendingCount}'),
                      const SizedBox(height: 8),
                      Text('Checked at: ${repaired.checkedAt}'),
                    ],
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(repairDialogCtx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } catch (e) {
          if (!ctx.mounted) return;
          messenger.showSnackBar(SnackBar(content: Text('Repair failed: $e')));
        }
      }

      await showDialog(
        context: ctx,
        builder:
            (dialogCtx) => AlertDialog(
              title: const Text('Notification Health'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plugin initialized: ${status.initialized}'),
                  Text('Permission state: $enabledText'),
                  Text('Pending notifications: ${status.pendingCount}'),
                  const SizedBox(height: 8),
                  Text('Settings box open: ${status.settingsBoxOpen}'),
                  Text('Habits box open: ${status.habitsBoxOpen}'),
                  Text('Entries box open: ${status.entriesBoxOpen}'),
                  const SizedBox(height: 8),
                  Text('Checked at: ${status.checkedAt}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    runRepair();
                  },
                  child: const Text('Repair'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Health check failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final profile = ref.watch(userProfileProvider);
    final ts = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'U',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: theme.textTheme.titleLarge),
                          Text(
                            'Level ${profile.level} ${profile.levelName}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Joined ${DateHelper.formatDate(profile.joinDate)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editName(context, ref, profile),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _sec(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.auto_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {ts.themeMode},
              onSelectionChanged:
                  (s) => ref.read(themeProvider.notifier).setThemeMode(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Accent Color'),
            subtitle: Wrap(
              spacing: 6,
              children:
                  AppConstants.accentColors.map((c) {
                    final sel = ts.accentColor == c;
                    return GestureDetector(
                      onTap:
                          () => ref
                              .read(themeProvider.notifier)
                              .setAccentColor(c),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border:
                              sel
                                  ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child:
                            sel
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
          _sec(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Morning Reminder'),
            subtitle: Text(
              _getBool('morning_reminder')
                  ? 'Daily at ${_getInt('morning_reminder_hour', 8).toString().padLeft(2, '0')}:${_getInt('morning_reminder_minute', 0).toString().padLeft(2, '0')}'
                  : 'Off',
            ),
            value: _getBool('morning_reminder'),
            onChanged: (v) => _toggleSetting('morning_reminder', v),
          ),
          if (_getBool('morning_reminder'))
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Morning Time'),
              trailing: TextButton(
                onPressed:
                    () => _pickTime(
                      context,
                      'morning_reminder_hour',
                      'morning_reminder_minute',
                    ),
                child: Text(
                  '${_getInt('morning_reminder_hour', 8).toString().padLeft(2, '0')}:${_getInt('morning_reminder_minute', 0).toString().padLeft(2, '0')}',
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.nights_stay_outlined),
            title: const Text('Evening Summary'),
            subtitle: Text(
              _getBool('evening_reminder')
                  ? 'Daily at ${_getInt('evening_reminder_hour', 21).toString().padLeft(2, '0')}:${_getInt('evening_reminder_minute', 0).toString().padLeft(2, '0')}'
                  : 'Off',
            ),
            value: _getBool('evening_reminder'),
            onChanged: (v) => _toggleSetting('evening_reminder', v),
          ),
          if (_getBool('evening_reminder'))
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Evening Time'),
              trailing: TextButton(
                onPressed:
                    () => _pickTime(
                      context,
                      'evening_reminder_hour',
                      'evening_reminder_minute',
                    ),
                child: Text(
                  '${_getInt('evening_reminder_hour', 21).toString().padLeft(2, '0')}:${_getInt('evening_reminder_minute', 0).toString().padLeft(2, '0')}',
                ),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Streak at Risk Alert'),
            subtitle: const Text('Notify at 10 PM if habits are incomplete'),
            value: _getBool('streak_alert'),
            onChanged: (v) => _toggleSetting('streak_alert', v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bar_chart_outlined),
            title: const Text('Weekly Report'),
            subtitle: const Text('Summary every Sunday at 10 AM'),
            value: _getBool('weekly_report'),
            onChanged: (v) => _toggleSetting('weekly_report', v),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Notification Health Check'),
            subtitle: const Text(
              'Verify permission, pending schedules, and storage readiness',
            ),
            onTap: () => _runNotificationHealthCheck(context),
          ),
          _sec(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Backup to JSON'),
            onTap: () => _backup(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _clearAll(context, ref),
          ),
          _sec(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text(AppConstants.version),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sec(BuildContext ctx, String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      t,
      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
        color: Theme.of(ctx).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _editName(BuildContext ctx, WidgetRef ref, UserProfile profile) {
    final c = TextEditingController(text: profile.name);
    showDialog(
      context: ctx,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final box = Hive.box<UserProfile>('user_profile');
                  final p = box.get('profile') ?? UserProfile();
                  p.name = c.text.trim();
                  box.put('profile', p);
                  ref.invalidate(userProfileProvider);
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _backup(BuildContext ctx) async {
    try {
      final habits =
          Hive.box<HabitModel>('habits').values.map((h) => h.toJson()).toList();
      final entries =
          Hive.box<HabitEntry>(
            'habit_entries',
          ).values.map((e) => e.toJson()).toList();
      final profile =
          Hive.box<UserProfile>('user_profile').get('profile')?.toJson();
      final data = jsonEncode({
        'habits': habits,
        'entries': entries,
        'profile': profile,
      });
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/habitforge_backup.json');
      await file.writeAsString(data);
      await Share.shareXFiles([XFile(file.path)], text: 'HabitForge Backup');
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  void _clearAll(BuildContext ctx, WidgetRef ref) {
    showDialog(
      context: ctx,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Hive.box<HabitModel>('habits').clear();
                  Hive.box<HabitEntry>('habit_entries').clear();
                  Hive.box<Achievement>('achievements').clear();
                  Hive.box<UserProfile>('user_profile').clear();
                  NotificationService().cancelAll();
                  ref.invalidate(habitProvider);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('All data cleared.')),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
    );
  }
}
