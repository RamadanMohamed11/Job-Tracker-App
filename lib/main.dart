import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/theme/theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/notification_service.dart';
import 'core/utils/page_transitions.dart';
import 'data/local/database_service.dart';
import 'presentation/cubits/cubits.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/job_details/job_details_screen.dart';

// Global navigator key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global JobsCubit reference for notification handling
JobsCubit? _globalJobsCubit;

// ============================================
// WHAT IS THIS FILE?
// ============================================
// main.dart is the entry point of the Flutter application.
// It does 4 things before showing the UI:
// 1. Initialize Hive database
// 2. Initialize HydratedBloc storage (for persisting theme)
// 3. Initialize Notification Service (for follow-up reminders)
// 4. Set up Bloc providers (makes Cubits available to the widget tree)

void main() async {
  // ============================================
  // STEP 1: Ensure Flutter is initialized
  // ============================================
  // This is required before calling any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // STEP 2: Initialize Hive Database
  // ============================================
  // This sets up the local storage for job applications.
  await DatabaseService.instance.initialize();

  // ============================================
  // STEP 3: Initialize HydratedBloc Storage
  // ============================================
  // HydratedBloc needs a storage location to persist Cubit states.
  // We use the app's documents directory.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  // ============================================
  // STEP 4: Initialize Notification Service
  // ============================================
  // This sets up local notifications for follow-up reminders.
  await NotificationService().initialize();

  // Set up notification tap handler
  NotificationService.onNotificationTap = (jobId) {
    if (jobId != null) {
      _handleNotificationTap(jobId);
    }
  };

  // ============================================
  // STEP 5: Run the App
  // ============================================
  runApp(const JobTrackerApp());
}

// ============================================
// NOTIFICATION TAP HANDLER
// ============================================
// Opens job details when user taps on a notification.
void _handleNotificationTap(String jobId) {
  // Use a delay to ensure the app is fully loaded
  Future.delayed(const Duration(milliseconds: 500), () {
    final navigatorState = navigatorKey.currentState;
    final jobsCubit = _globalJobsCubit;

    if (navigatorState != null && jobsCubit != null) {
      final job = jobsCubit.getJobById(jobId);

      if (job != null) {
        navigatorState.push(
          FadeSlidePageRoute(page: JobDetailsScreen(job: job)),
        );
      }
    }
  });
}

// ============================================
// ROOT WIDGET
// ============================================
// JobTrackerApp is the root widget that sets up:
// - Bloc providers (state management)
// - Theme (light/dark mode)
// - Navigation (which screen to show)
class JobTrackerApp extends StatelessWidget {
  const JobTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ============================================
    // MULTI BLOC PROVIDER
    // ============================================
    // MultiBlocProvider wraps the app with multiple Cubits.
    // Any widget in the tree can access these Cubits using:
    //   context.read<ThemeCubit>()
    //   context.watch<JobsCubit>().state
    return MultiBlocProvider(
      providers: [
        // Theme Cubit - manages light/dark mode
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        // Jobs Cubit - manages job applications
        BlocProvider<JobsCubit>(
          create: (_) {
            final cubit = JobsCubit()..loadJobs();
            _globalJobsCubit = cubit; // Store global reference
            return cubit;
          },
        ),
      ],
      child: const _AppWithTheme(),
    );
  }
}

// ============================================
// APP WITH THEME
// ============================================
// Separate widget that listens to ThemeCubit and rebuilds
// when theme changes.
class _AppWithTheme extends StatelessWidget {
  const _AppWithTheme();

  @override
  Widget build(BuildContext context) {
    // ============================================
    // BLOC BUILDER
    // ============================================
    // BlocBuilder rebuilds this widget when ThemeCubit emits new state.
    // We use it to update the MaterialApp's themeMode.
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          // App title (shown in task switcher)
          title: AppStrings.appName,

          // Disable the debug banner
          debugShowCheckedModeBanner: false,

          // Navigator key for handling notification taps
          navigatorKey: navigatorKey,

          // Light theme configuration
          theme: AppTheme.lightTheme,

          // Dark theme configuration
          darkTheme: AppTheme.darkTheme,

          // Which theme to use: light, dark, or system
          themeMode: themeState.flutterThemeMode,

          // Home screen
          home: const HomeScreen(),
        );
      },
    );
  }
}
