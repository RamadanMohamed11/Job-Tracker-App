import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// ThemeCubit manages the app's theme state (light/dark/system).
// It uses HydratedCubit which automatically saves and restores
// the theme preference even after the app is closed and reopened.
//
// CUBIT vs BLOC:
// - Cubit is simpler: you call methods that emit new states
// - Bloc uses events: you add events that are processed into states
// - For simple state like theme, Cubit is perfect!

// ============================================
// THEME MODE ENUM
// ============================================
// Represents the three possible theme modes:
// - system: Follow the device's theme setting
// - light: Always use light theme
// - dark: Always use dark theme
enum AppThemeMode { system, light, dark }

// ============================================
// THEME STATE
// ============================================
// The state class holds the current theme mode.
// It's immutable - we create new instances instead of modifying.
class ThemeState {
  final AppThemeMode themeMode;

  const ThemeState({this.themeMode = AppThemeMode.system});

  // Convert Flutter's ThemeMode to our AppThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Check if dark mode is active (considering system setting)
  bool isDark(BuildContext context) {
    if (themeMode == AppThemeMode.dark) return true;
    if (themeMode == AppThemeMode.light) return false;
    // If system, check the platform brightness
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // Create a copy with different values
  ThemeState copyWith({AppThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  // Equality check - needed for Cubit to know if state changed
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState && other.themeMode == themeMode;
  }

  @override
  int get hashCode => themeMode.hashCode;

  // Convert to JSON for persistence (HydratedBloc)
  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.index};
  }

  // Create from JSON when restoring (HydratedBloc)
  factory ThemeState.fromJson(Map<String, dynamic> json) {
    final index = json['themeMode'] as int? ?? 0;
    return ThemeState(
      themeMode:
          AppThemeMode.values[index.clamp(0, AppThemeMode.values.length - 1)],
    );
  }
}

// ============================================
// THEME CUBIT
// ============================================
// HydratedCubit automatically saves state to disk and restores it.
// This means the user's theme preference persists across app restarts!
class ThemeCubit extends HydratedCubit<ThemeState> {
  // Constructor - starts with system theme
  ThemeCubit() : super(const ThemeState());

  // ============================================
  // METHODS TO CHANGE THEME
  // ============================================

  /// Set theme to light mode
  void setLightMode() {
    emit(state.copyWith(themeMode: AppThemeMode.light));
  }

  /// Set theme to dark mode
  void setDarkMode() {
    emit(state.copyWith(themeMode: AppThemeMode.dark));
  }

  /// Set theme to follow system setting
  void setSystemMode() {
    emit(state.copyWith(themeMode: AppThemeMode.system));
  }

  /// Set theme mode directly
  void setThemeMode(AppThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  /// Toggle between light and dark (ignores system)
  void toggleTheme() {
    if (state.themeMode == AppThemeMode.dark) {
      emit(state.copyWith(themeMode: AppThemeMode.light));
    } else {
      emit(state.copyWith(themeMode: AppThemeMode.dark));
    }
  }

  // ============================================
  // HYDRATED CUBIT METHODS
  // ============================================
  // These are required by HydratedCubit for persistence.

  /// Convert state to JSON for saving
  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    return state.toJson();
  }

  /// Restore state from JSON
  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      return ThemeState.fromJson(json);
    } catch (_) {
      return const ThemeState();
    }
  }
}
