import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/shell_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/statistics/statistics_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/habit/create_habit_screen.dart';
import '../../screens/habit/habit_detail_screen.dart';
import '../../screens/templates/templates_screen.dart';
import '../../screens/achievements/achievements_screen.dart';
import '../../screens/focus/focus_timer_screen.dart';
import '../../screens/mood/mood_screen.dart';
import '../../screens/journal/journal_screen.dart';
import '../../screens/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/create-habit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final templateIndex = state.uri.queryParameters['template'];
          return CreateHabitScreen(
            templateIndex:
                templateIndex != null ? int.tryParse(templateIndex) : null,
          );
        },
      ),
      GoRoute(
        path: '/edit-habit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (context, state) =>
                CreateHabitScreen(habitId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/habit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder:
            (context, state) =>
                HabitDetailScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/templates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/achievements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/focus',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FocusTimerScreen(),
      ),
      GoRoute(
        path: '/mood',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MoodScreen(),
      ),
      GoRoute(
        path: '/journal',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JournalScreen(),
      ),
    ],
  );
});
