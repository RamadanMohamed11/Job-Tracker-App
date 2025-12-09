import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/theme/theme.dart';
import 'core/constants/app_strings.dart';
import 'data/local/database_service.dart';
import 'presentation/cubits/cubits.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// main.dart is the entry point of the Flutter application.
// It does 3 things before showing the UI:
// 1. Initialize Hive database
// 2. Initialize HydratedBloc storage (for persisting theme)
// 3. Set up Bloc providers (makes Cubits available to the widget tree)

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
  // STEP 4: Run the App
  // ============================================
  runApp(const JobTrackerApp());
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
        BlocProvider<JobsCubit>(create: (_) => JobsCubit()..loadJobs()),
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

          // Light theme configuration
          theme: AppTheme.lightTheme,

          // Dark theme configuration
          darkTheme: AppTheme.darkTheme,

          // Which theme to use: light, dark, or system
          themeMode: themeState.flutterThemeMode,

          // Home screen - we'll create this next!
          // For now, show a placeholder
          home: const _PlaceholderHomeScreen(),
        );
      },
    );
  }
}

// ============================================
// PLACEHOLDER HOME SCREEN
// ============================================
// Temporary screen until we build the real UI.
// This lets us test that everything works.
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              // Toggle theme when pressed
              context.read<ThemeCubit>().toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Theme & Bloc setup complete!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            // Show current job count from JobsCubit
            BlocBuilder<JobsCubit, JobsState>(
              builder: (context, state) {
                return Text(
                  'Total Jobs: ${state.totalCount}',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder - will navigate to add job screen later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Job screen coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
