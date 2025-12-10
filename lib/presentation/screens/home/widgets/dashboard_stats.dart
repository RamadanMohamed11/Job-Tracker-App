import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/job_application.dart';
import '../../../../core/constants/status_options.dart';
import '../../../cubits/jobs_cubit.dart';

// ============================================
// DASHBOARD STATS WIDGET
// ============================================
// Displays clickable statistics cards showing:
// - Total jobs
// - Interviews scheduled
// - Pending follow-ups
// - Success rate
// Clicking a card filters the job list to show only relevant jobs.

class DashboardStats extends StatelessWidget {
  final List<JobApplication> jobs;

  const DashboardStats({super.key, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<JobsCubit, JobsState>(
      buildWhen: (previous, current) =>
          previous.dashboardFilter != current.dashboardFilter,
      builder: (context, state) {
        final activeFilter = state.dashboardFilter;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title with clear filter option
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dashboard',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show clear filter button when a filter is active
                    if (activeFilter != DashboardFilter.none &&
                        activeFilter != DashboardFilter.totalJobs)
                      TextButton.icon(
                        onPressed: () =>
                            context.read<JobsCubit>().clearDashboardFilter(),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Jobs',
                      value: stats.totalJobs.toString(),
                      icon: Icons.work_outline,
                      color: Colors.blue,
                      isDark: isDark,
                      isActive: activeFilter == DashboardFilter.totalJobs,
                      onTap: () => context.read<JobsCubit>().setDashboardFilter(
                        DashboardFilter.totalJobs,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Interviews',
                      value: stats.interviews.toString(),
                      icon: Icons.event_available,
                      color: Colors.orange,
                      isDark: isDark,
                      isActive: activeFilter == DashboardFilter.interviews,
                      onTap: () => context.read<JobsCubit>().setDashboardFilter(
                        DashboardFilter.interviews,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Follow-ups',
                      value: stats.pendingFollowUps.toString(),
                      icon: Icons.notifications_active,
                      color: Colors.purple,
                      isDark: isDark,
                      subtitle: 'pending',
                      isActive: activeFilter == DashboardFilter.followUps,
                      onTap: () => context.read<JobsCubit>().setDashboardFilter(
                        DashboardFilter.followUps,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Success',
                      value: '${stats.successRate.toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: stats.successRate > 20
                          ? Colors.green
                          : Colors.grey,
                      isDark: isDark,
                      isActive: activeFilter == DashboardFilter.successful,
                      onTap: () => context.read<JobsCubit>().setDashboardFilter(
                        DashboardFilter.successful,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  _DashboardData _calculateStats() {
    final now = DateTime.now();

    // Total jobs
    final totalJobs = jobs.length;

    // Interviews (status = interviewScheduled or interviewed)
    final interviews = jobs
        .where(
          (job) =>
              job.statusEnum == JobStatus.interviewScheduled ||
              job.statusEnum == JobStatus.interviewed,
        )
        .length;

    // Pending follow-ups (follow-up date is in the future or today)
    final pendingFollowUps = jobs.where((job) {
      if (job.followUpDate == null || job.followUpDate!.isEmpty) return false;
      try {
        final followUpDate = DateTime.parse(job.followUpDate!);
        return followUpDate.isAfter(now) || _isSameDay(followUpDate, now);
      } catch (_) {
        return false;
      }
    }).length;

    // Success rate (offers received or accepted / completed applications)
    final successfulJobs = jobs
        .where(
          (job) =>
              job.statusEnum == JobStatus.offerReceived ||
              job.statusEnum == JobStatus.accepted,
        )
        .length;

    final completedJobs = jobs
        .where(
          (job) =>
              job.statusEnum == JobStatus.offerReceived ||
              job.statusEnum == JobStatus.accepted ||
              job.statusEnum == JobStatus.rejected ||
              job.statusEnum == JobStatus.withdrawn,
        )
        .length;

    final successRate = completedJobs > 0
        ? (successfulJobs / completedJobs) * 100
        : 0.0;

    return _DashboardData(
      totalJobs: totalJobs,
      interviews: interviews,
      pendingFollowUps: pendingFollowUps,
      successRate: successRate,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Data class for dashboard statistics
class _DashboardData {
  final int totalJobs;
  final int interviews;
  final int pendingFollowUps;
  final double successRate;

  _DashboardData({
    required this.totalJobs,
    required this.interviews,
    required this.pendingFollowUps,
    required this.successRate,
  });
}

// ============================================
// STAT CARD WIDGET
// ============================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? subtitle;
  final bool isActive;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.subtitle,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? color.withAlpha(isDark ? 80 : 60)
                : (isDark ? color.withAlpha(30) : color.withAlpha(20)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : color.withAlpha(isDark ? 60 : 40),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and value row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 50 : 30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
