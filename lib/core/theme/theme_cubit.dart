import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// ThemeCubit manages the app's theme state (light/dark/system)
// and notification time settings.
// It uses HydratedCubit which automatically saves and restores
// preferences even after the app is closed and reopened.
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
// The state class holds the current theme mode, notification time, and custom colors.
// It's immutable - we create new instances instead of modifying.
class ThemeState {
  final AppThemeMode themeMode;
  final int notificationHour; // 0-23
  final int notificationMinute; // 0-59
  final int primaryColorValue; // Custom primary color as int (Color.value)

  // Preset color options for users to choose from
  static const List<int> presetColors = [
    0xFF3B82F6, // Blue (default)
    0xFF10B981, // Emerald
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFF06B6D4, // Cyan
    0xFFEF4444, // Red
    0xFF6366F1, // Indigo
    0xFF14B8A6, // Teal
    0xFFF97316, // Orange
  ];

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.notificationHour = 9, // Default: 9:00 AM
    this.notificationMinute = 0,
    this.primaryColorValue = 0xFF3B82F6, // Default blue
  });

  // Get primary color as Color object
  Color get primaryColor => Color(primaryColorValue);

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
  ThemeState copyWith({
    AppThemeMode? themeMode,
    int? notificationHour,
    int? notificationMinute,
    int? primaryColorValue,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
    );
  }

  // Get notification time as TimeOfDay
  TimeOfDay get notificationTime =>
      TimeOfDay(hour: notificationHour, minute: notificationMinute);

  // Format notification time for display
  String get formattedNotificationTime {
    final hour = notificationHour;
    final minute = notificationMinute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // Equality check - needed for Cubit to know if state changed
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.notificationHour == notificationHour &&
        other.notificationMinute == notificationMinute &&
        other.primaryColorValue == primaryColorValue;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    notificationHour,
    notificationMinute,
    primaryColorValue,
  );

  // Convert to JSON for persistence (HydratedBloc)
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
      'primaryColorValue': primaryColorValue,
    };
  }

  // Create from JSON when restoring (HydratedBloc)
  factory ThemeState.fromJson(Map<String, dynamic> json) {
    final index = json['themeMode'] as int? ?? 0;
    return ThemeState(
      themeMode:
          AppThemeMode.values[index.clamp(0, AppThemeMode.values.length - 1)],
      notificationHour: (json['notificationHour'] as int?) ?? 9,
      notificationMinute: (json['notificationMinute'] as int?) ?? 0,
      primaryColorValue: (json['primaryColorValue'] as int?) ?? 0xFF3B82F6,
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
  // NOTIFICATION TIME METHODS
  // ============================================

  /// Set the notification time
  void setNotificationTime(TimeOfDay time) {
    emit(
      state.copyWith(
        notificationHour: time.hour,
        notificationMinute: time.minute,
      ),
    );
  }

  // ============================================
  // CUSTOM COLOR METHODS
  // ============================================

  /// Set the primary color
  void setPrimaryColor(int colorValue) {
    emit(state.copyWith(primaryColorValue: colorValue));
  }

  /// Reset to default blue color
  void resetPrimaryColor() {
    emit(state.copyWith(primaryColorValue: 0xFF3B82F6));
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
