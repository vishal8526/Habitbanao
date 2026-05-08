import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'models/habit_model.dart';
import 'models/habit_entry.dart';
import 'models/achievement.dart';
import 'models/user_profile.dart';
import 'models/mood_entry.dart';
import 'models/journal_entry.dart';
import 'services/notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitEntryAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AchievementAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(UserProfileAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MoodEntryAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(JournalEntryAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(HabitTypeAdapter());
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(FrequencyTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(TimeOfDayCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(MoodLevelAdapter());

  // Open only minimal boxes needed for app bootstrap before runApp
  final results = await Future.wait([
    Hive.openBox<UserProfile>('user_profile'),
    Hive.openBox('settings'),
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[2] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const HabitForgeApp(),
    ),
  );

  // Delay non-critical work to reduce first-route jank.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(Duration(seconds: kDebugMode ? 5 : 3), () async {
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox<HabitModel>('habits');
      }
      if (!Hive.isBoxOpen('habit_entries')) {
        await Hive.openBox<HabitEntry>('habit_entries');
      }
      if (!Hive.isBoxOpen('achievements')) {
        await Hive.openBox<Achievement>('achievements');
      }
      if (!Hive.isBoxOpen('mood_entries')) {
        await Hive.openBox<MoodEntry>('mood_entries');
      }
      if (!Hive.isBoxOpen('journal_entries')) {
        await Hive.openBox<JournalEntry>('journal_entries');
      }

      await Future.delayed(const Duration(seconds: 2));
      final notifService = NotificationService();
      await notifService.initialize();
      await notifService.syncWithSettings();
    });
  });
}
