import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color accentColor;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF4CAF50),
  });

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: accentColor,
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: accentColor,
  );

  ThemeState copyWith({ThemeMode? themeMode, Color? accentColor}) => ThemeState(
    themeMode: themeMode ?? this.themeMode,
    accentColor: accentColor ?? this.accentColor,
  );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box<UserProfile>('user_profile');
      final profile = box.get('profile');
      if (profile != null) {
        state = ThemeState(
          themeMode: ThemeMode.values[profile.selectedThemeMode.clamp(0, 2)],
          accentColor: Color(profile.selectedAccentColor),
        );
      }
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    _save();
  }

  void _save() {
    try {
      final box = Hive.box<UserProfile>('user_profile');
      final profile = box.get('profile') ?? UserProfile();
      profile.selectedThemeMode = state.themeMode.index;
      profile.selectedAccentColor = state.accentColor.toARGB32();
      box.put('profile', profile);
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
