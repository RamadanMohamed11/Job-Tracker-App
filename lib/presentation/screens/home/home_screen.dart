import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/constants.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/utils/animations.dart';
import '../../cubits/jobs_cubit.dart';
import 'widgets/job_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/filter_sort_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/dashboard_stats.dart';
import '../job_form/job_form_screen.dart';
import '../job_details/job_details_screen.dart';
import '../settings/settings_screen.dart';

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
// - Multi-select mode for bulk delete

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobsCubit, JobsState>(
      buildWhen: (previous, current) =>
          previous.isSelectionMode != current.isSelectionMode ||
          previous.selectedCount != current.selectedCount,
      builder: (context, state) {
        return Scaffold(
          // ============================================
          // APP BAR (changes in selection mode)
          // ============================================
          appBar: state.isSelectionMode
              ? _buildSelectionAppBar(context, state)
              : _buildNormalAppBar(context),

          // ============================================
          // BODY
          // ============================================
          body: Column(
            children: [
              // Hide search/filter in selection mode
              if (!state.isSelectionMode) ...[
                const SearchBarWidget(),
                const FilterSortBar(),
              ],

              // Job count / selection count display
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: BlocBuilder<JobsCubit, JobsState>(
                  builder: (context, state) {
                    if (state.isSelectionMode) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${state.selectedCount} selected',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      );
                    }
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

                    // Show empty state only if NO jobs exist at all
                    if (state.jobs.isEmpty) {
                      return const EmptyStateWidget(
                        hasFilters: false,
                        onClearFilters: null,
                      );
                    }

                    // Jobs exist - show dashboard + job list (or filtered empty state)
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<JobsCubit>().loadJobs();
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
                          // Dashboard is always visible when jobs exist
                          DashboardStats(jobs: state.jobs),

                          // Show filtered empty state or job cards
                          if (state.filteredJobs.isEmpty)
                            _buildFilteredEmptyState(context, state)
                          else
                            ...state.filteredJobs.asMap().entries.map((entry) {
                              final jobIndex = entry.key;
                              final job = entry.value;
                              final isSelected = state.isSelected(job.id);

                              return StaggeredAnimationWrapper(
                                index: jobIndex,
                                child: _SelectableJobCard(
                                  job: job,
                                  isSelectionMode: state.isSelectionMode,
                                  isSelected: isSelected,
                                  onTap: () =>
                                      _handleJobTap(context, state, job),
                                  onLongPress: () =>
                                      _handleJobLongPress(context, state, job),
                                  onEdit: () {
                                    Navigator.push(
                                      context,
                                      FadeSlidePageRoute(
                                        page: JobFormScreen(jobToEdit: job),
                                      ),
                                    );
                                  },
                                  onDelete: () => _confirmDelete(
                                    context,
                                    job.id,
                                    job.jobName,
                                  ),
                                  onPin: () => context
                                      .read<JobsCubit>()
                                      .togglePin(job.id),
                                  onArchive: () => context
                                      .read<JobsCubit>()
                                      .toggleArchive(job.id),
                                ),
                              );
                            }),
                        ],
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
          floatingActionButton: state.isSelectionMode
              ? null // Hide FAB in selection mode
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(page: const JobFormScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addJob),
                ),
        );
      },
    );
  }

  // ============================================
  // NORMAL APP BAR
  // ============================================
  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: const Text(AppStrings.appName),
      actions: [
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
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: AppStrings.settings,
          onPressed: () {
            Navigator.push(
              context,
              FadeSlidePageRoute(page: const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ============================================
  // SELECTION MODE APP BAR
  // ============================================
  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    JobsState state,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.read<JobsCubit>().exitSelectionMode(),
        tooltip: 'Cancel selection',
      ),
      title: Text('${state.selectedCount} selected'),
      actions: [
        // Select All button
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => context.read<JobsCubit>().selectAllJobs(),
          tooltip: 'Select all',
        ),
        // Delete selected button
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: state.selectedCount > 0
              ? () => _confirmDeleteSelected(context, state.selectedCount)
              : null,
          tooltip: 'Delete selected',
        ),
      ],
    );
  }

  // ============================================
  // JOB TAP HANDLER
  // ============================================
  void _handleJobTap(BuildContext context, JobsState state, dynamic job) {
    if (state.isSelectionMode) {
      // In selection mode, tap toggles selection
      context.read<JobsCubit>().toggleJobSelection(job.id);
    } else {
      // Normal mode, navigate to details
      Navigator.push(
        context,
        FadeSlidePageRoute(page: JobDetailsScreen(job: job)),
      );
    }
  }

  // ============================================
  // JOB LONG PRESS HANDLER
  // ============================================
  void _handleJobLongPress(BuildContext context, JobsState state, dynamic job) {
    if (!state.isSelectionMode) {
      // Enter selection mode with this job selected
      context.read<JobsCubit>().enterSelectionMode(job.id);
    }
  }

  // ============================================
  // FILTERED EMPTY STATE
  // ============================================
  Widget _buildFilteredEmptyState(BuildContext context, JobsState state) {
    String message;
    String buttonText;
    VoidCallback onClear;

    if (state.dashboardFilter != DashboardFilter.none &&
        state.dashboardFilter != DashboardFilter.totalJobs) {
      // Dashboard filter active
      switch (state.dashboardFilter) {
        case DashboardFilter.interviews:
          message = 'No interview jobs found';
          break;
        case DashboardFilter.followUps:
          message = 'No pending follow-ups';
          break;
        case DashboardFilter.successful:
          message = 'No successful applications yet';
          break;
        default:
          message = 'No jobs match this filter';
      }
      buttonText = 'Clear Dashboard Filter';
      onClear = () => context.read<JobsCubit>().clearDashboardFilter();
    } else if (state.searchQuery.isNotEmpty || state.statusFilter != null) {
      // Search or status filter active
      message = 'No jobs match your filters';
      buttonText = 'Clear Filters';
      onClear = () {
        context.read<JobsCubit>().clearSearch();
        context.read<JobsCubit>().clearStatusFilter();
      };
    } else {
      message = 'No jobs found';
      buttonText = 'Refresh';
      onClear = () => context.read<JobsCubit>().loadJobs();
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DELETE CONFIRMATION DIALOG (single)
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

  // ============================================
  // DELETE CONFIRMATION DIALOG (multiple)
  // ============================================
  void _confirmDeleteSelected(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected Jobs?'),
        content: Text(
          'Are you sure you want to delete $count job${count > 1 ? 's' : ''}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<JobsCubit>().deleteSelectedJobs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count job${count > 1 ? 's' : ''} deleted'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete $count'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SELECTABLE JOB CARD WRAPPER
// ============================================
// Wraps JobCard with selection behavior and visual feedback
class _SelectableJobCard extends StatelessWidget {
  final dynamic job;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onArchive;

  const _SelectableJobCard({
    required this.job,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Selection highlight background
        if (isSelected)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        // The actual job card
        JobCard(
          job: job,
          onTap: onTap,
          onLongPress: onLongPress,
          onEdit: isSelectionMode ? null : onEdit,
          onDelete: isSelectionMode ? null : onDelete,
          onPin: isSelectionMode ? null : onPin,
          onArchive: isSelectionMode ? null : onArchive,
        ),
        // Selection checkbox overlay
        if (isSelectionMode)
          Positioned(
            right: 20,
            top: 12,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  isSelected ? Icons.check : null,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
