import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/shell_screen.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_habit_screen.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/templates_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/mood_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/create-habit',
        name: 'createHabit',
        builder:
            (context, state) => CreateHabitScreen(
              template: state.extra as Map<String, dynamic>?,
            ),
      ),
      GoRoute(
        path: '/edit-habit/:id',
        name: 'editHabit',
        builder:
            (context, state) =>
                CreateHabitScreen(habitId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/habit/:id',
        name: 'habitDetail',
        builder:
            (context, state) =>
                HabitDetailScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/templates',
        name: 'templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/focus-timer',
        name: 'focusTimer',
        builder: (context, state) => const FocusTimerScreen(),
      ),
      GoRoute(
        path: '/mood',
        name: 'mood',
        builder: (context, state) => const MoodScreen(),
      ),
      GoRoute(
        path: '/journal',
        name: 'journal',
        builder: (context, state) => const JournalScreen(),
      ),
    ],
  );
});
