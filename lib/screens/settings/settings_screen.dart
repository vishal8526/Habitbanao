import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hive_constants.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_entry_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileRepo = ref.watch(profileRepositoryProvider);
    final profile = profileRepo.getProfile();
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile
          _sectionHeader(theme, 'Profile'),
          ListTile(
            leading: CircleAvatar(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
              ),
            ),
            title: Text(profile.name),
            subtitle: Text(
              'Level ${profile.level} • ${AppConstants.levelNames[profile.level] ?? ""} • Joined ${profile.joinDate.day}/${profile.joinDate.month}/${profile.joinDate.year}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => _editName(context, ref, profile),
          ),

          // Appearance
          _sectionHeader(theme, 'Appearance'),
          ListTile(
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
              selected: {themeMode},
              onSelectionChanged: (v) {
                ref.read(themeModeProvider.notifier).set(v.first);
                profile.selectedThemeMode = v.first.index;
                profileRepo.saveProfile(profile);
              },
            ),
          ),
          ListTile(
            title: const Text('Accent Color'),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.accentColors.asMap().entries.map((e) {
                    final selected = accentColor.value == e.value.value;
                    return GestureDetector(
                      onTap: () {
                        ref.read(accentColorProvider.notifier).set(e.value);
                        profile.selectedAccentColorIndex = e.key;
                        profileRepo.saveProfile(profile);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                          border:
                              selected
                                  ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 3,
                                  )
                                  : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // General
          _sectionHeader(theme, 'General'),
          ListTile(
            title: const Text('Week starts on'),
            trailing: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Mon')),
                ButtonSegment(value: 7, label: Text('Sun')),
              ],
              selected: {profile.weekStartDay},
              onSelectionChanged: (v) {
                profile.weekStartDay = v.first;
                profileRepo.saveProfile(profile);
              },
            ),
          ),

          // Data
          _sectionHeader(theme, 'Data'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Export all data as JSON'),
            onTap: () => _backupData(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _clearData(context, ref),
          ),

          // About
          _sectionHeader(theme, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _editName(
    BuildContext context,
    WidgetRef ref,
    UserProfileModel profile,
  ) {
    final controller = TextEditingController(text: profile.name);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  profile.name = controller.text.trim();
                  ref.read(profileRepositoryProvider).saveProfile(profile);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final habitsBox = Hive.box<HabitModel>(HiveConstants.habitsBox);
      final entriesBox = Hive.box<HabitEntryModel>(HiveConstants.entriesBox);
      final profileBox = Hive.box<UserProfileModel>(HiveConstants.profileBox);

      final data = {
        'habits': habitsBox.values.map((h) => h.toJson()).toList(),
        'entries': entriesBox.values.map((e) => e.toJson()).toList(),
        'profile': profileBox.get(HiveConstants.profileKey)?.toJson(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/habitforge_backup.json');
      await file.writeAsString(jsonEncode(data));

      await Share.shareXFiles([XFile(file.path)], text: 'HabitForge Backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  void _clearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text(
              'This will permanently delete all habits, entries, and progress. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await Hive.box<HabitModel>(HiveConstants.habitsBox).clear();
                  await Hive.box<HabitEntryModel>(
                    HiveConstants.entriesBox,
                  ).clear();
                  ref.read(habitsProvider.notifier).refresh();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All data cleared')),
                    );
                  }
                },
                child: const Text('Delete Everything'),
              ),
            ],
          ),
    );
  }
}
