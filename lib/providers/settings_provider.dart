import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final profile = ref.read(profileRepositoryProvider).getProfile();
  return ThemeModeNotifier(ThemeMode.values[profile.selectedThemeMode]);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.initial);
  void set(ThemeMode mode) => state = mode;
}

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  final profile = ref.read(profileRepositoryProvider).getProfile();
  return AccentColorNotifier(
    AppConstants.accentColors[profile.selectedAccentColorIndex.clamp(0, 9)],
  );
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier(super.initial);
  void set(Color color) => state = color;
}
