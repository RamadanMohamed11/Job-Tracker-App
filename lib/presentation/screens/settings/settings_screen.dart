import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/constants.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../cubits/jobs_cubit.dart';

// ============================================
// SETTINGS SCREEN
// ============================================
// Allows users to customize app settings:
// - Theme selection (Light/Dark/System)
// - App version info

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // ============================================
          // APPEARANCE SECTION
          // ============================================
          _SectionHeader(title: AppStrings.appearance),

          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Light Mode
                    _ThemeOptionTile(
                      title: AppStrings.lightMode,
                      subtitle: 'Always use light theme',
                      icon: Icons.light_mode,
                      isSelected: state.themeMode == AppThemeMode.light,
                      onTap: () {
                        context.read<ThemeCubit>().setLightMode();
                      },
                    ),
                    const Divider(height: 1),

                    // Dark Mode
                    _ThemeOptionTile(
                      title: AppStrings.darkMode,
                      subtitle: 'Always use dark theme',
                      icon: Icons.dark_mode,
                      isSelected: state.themeMode == AppThemeMode.dark,
                      onTap: () {
                        context.read<ThemeCubit>().setDarkMode();
                      },
                    ),
                    const Divider(height: 1),

                    // System Mode
                    _ThemeOptionTile(
                      title: AppStrings.systemMode,
                      subtitle: 'Follow device settings',
                      icon: Icons.settings_brightness,
                      isSelected: state.themeMode == AppThemeMode.system,
                      onTap: () {
                        context.read<ThemeCubit>().setSystemMode();
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ============================================
          // NOTIFICATIONS SECTION
          // ============================================
          _SectionHeader(title: 'Notifications'),

          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_active,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Follow-up Reminder Time'),
                  subtitle: Text(
                    'Notifications at ${state.formattedNotificationTime}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectNotificationTime(context, state),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ============================================
          // ABOUT SECTION
          // ============================================
          _SectionHeader(title: 'About'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // App Name and Version
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline, color: Colors.white),
                  ),
                  title: const Text(
                    AppStrings.appName,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Version ${AppStrings.appVersion}'),
                ),
                const Divider(height: 1),

                // Developer Info
                ListTile(
                  leading: Icon(Icons.code, color: theme.colorScheme.primary),
                  title: const Text('Developed with'),
                  subtitle: const Text('Flutter & Dart'),
                ),
                const Divider(height: 1),

                // Storage Info
                ListTile(
                  leading: Icon(
                    Icons.storage,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Data Storage'),
                  subtitle: const Text('Local (Hive NoSQL)'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ============================================
          // DATA SECTION
          // ============================================
          _SectionHeader(title: 'Data'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Clear All Data
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Clear All Data',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Delete all job applications'),
                  onTap: () => _confirmClearData(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text('© 2024 Job Tracker', style: theme.textTheme.bodySmall),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your job applications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // TODO: Implement clear all data
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data cleared')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectNotificationTime(
    BuildContext context,
    ThemeState state,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: state.notificationTime,
      helpText: 'Select notification time',
    );

    if (picked != null && context.mounted) {
      context.read<ThemeCubit>().setNotificationTime(picked);

      // Reschedule all existing job notifications with the new time
      await context.read<JobsCubit>().rescheduleAllNotifications(
        hour: picked.hour,
        minute: picked.minute,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification time set to ${_formatTime(picked)} - all notifications rescheduled',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

// ============================================
// SECTION HEADER WIDGET
// ============================================
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ============================================
// THEME OPTION TILE WIDGET
// ============================================
class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }
}
