import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/constants.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../cubits/jobs_cubit.dart';
import 'widgets/job_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/filter_sort_bar.dart';
import 'widgets/empty_state.dart';

// ============================================
// HOME SCREEN
// ============================================
// The main screen that displays:
// - App bar with title and theme toggle
// - Search bar
// - Filter and sort controls
// - List of job cards
// - FAB to add new job
// - Empty state when no jobs exist

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================
      // APP BAR
      // ============================================
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Theme toggle button
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.themeMode == AppThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                tooltip: 'Toggle Theme',
              );
            },
          ),
        ],
      ),

      // ============================================
      // BODY
      // ============================================
      body: Column(
        children: [
          // Search bar at the top
          const SearchBarWidget(),

          // Filter and sort controls
          const FilterSortBar(),

          // Job count display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<JobsCubit, JobsState>(
              builder: (context, state) {
                final count = state.displayedCount;
                final total = state.totalCount;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${AppStrings.showingJobs} $count ${count == 1 ? AppStrings.job : AppStrings.jobs}'
                    '${state.searchQuery.isNotEmpty || state.statusFilter != null ? ' (of $total)' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),

          // Job list or empty state
          Expanded(
            child: BlocBuilder<JobsCubit, JobsState>(
              builder: (context, state) {
                // Show loading indicator
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Show error message if any
                if (state.errorMessage != null) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<JobsCubit>().loadJobs(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show empty state if no jobs
                if (state.filteredJobs.isEmpty) {
                  return EmptyStateWidget(
                    hasFilters:
                        state.searchQuery.isNotEmpty ||
                        state.statusFilter != null,
                    onClearFilters: () {
                      context.read<JobsCubit>().clearSearch();
                      context.read<JobsCubit>().clearStatusFilter();
                    },
                  );
                }

                // Show job list
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<JobsCubit>().loadJobs();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: state.filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = state.filteredJobs[index];
                      return JobCard(
                        job: job,
                        onTap: () {
                          // TODO: Navigate to job details
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('View: ${job.jobName}')),
                          );
                        },
                        onEdit: () {
                          // TODO: Navigate to edit job
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edit: ${job.jobName}')),
                          );
                        },
                        onDelete: () =>
                            _confirmDelete(context, job.id, job.jobName),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ============================================
      // FLOATING ACTION BUTTON
      // ============================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add job screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Job screen coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addJob),
      ),
    );
  }

  // ============================================
  // DELETE CONFIRMATION DIALOG
  // ============================================
  void _confirmDelete(BuildContext context, String jobId, String jobName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('${AppStrings.deleteConfirmMessage}\n\nJob: $jobName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<JobsCubit>().deleteJob(jobId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.jobDeleted)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
