import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

class HabitForgeApp extends ConsumerWidget {
  const HabitForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HabitBanao',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      routerConfig: router,
    );
  }
}
