import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/models/job_application.dart';
import '../../cubits/jobs_cubit.dart';
import '../job_form/job_form_screen.dart';

// ============================================
// JOB DETAILS SCREEN
// ============================================
// Displays comprehensive information about a job application.
// Features:
// - All job fields displayed in organized sections
// - Status badge with color coding
// - Open job link button
// - Edit and Delete actions
// - Created/Updated timestamps

class JobDetailsScreen extends StatelessWidget {
  final JobApplication job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.jobDetails),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppStrings.edit,
            onPressed: () => _navigateToEdit(context),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.delete,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // HEADER: Job Name & Status
            // ============================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    _StatusBadge(status: job.statusEnum, isDark: isDark),
                    const SizedBox(height: 12),

                    // Job name
                    Text(
                      job.jobName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    // Company name
                    if (job.companyName != null &&
                        job.companyName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        job.companyName!,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================
            // JOB LINK (if available)
            // ============================================
            if (job.jobLink != null && job.jobLink!.isNotEmpty) ...[
              _ActionCard(
                icon: Icons.link,
                title: AppStrings.jobLink,
                subtitle: job.jobLink!,
                actionLabel: 'Open Link',
                onAction: () => _openLink(context, job.jobLink!),
              ),
              const SizedBox(height: 16),
            ],

            // ============================================
            // APPLICATION DETAILS SECTION
            // ============================================
            _SectionCard(
              title: AppStrings.applicationDetails,
              children: [
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: AppStrings.applicationDate,
                  value: _formatDate(job.applicationDate),
                ),
                _DetailRow(
                  icon: Icons.source,
                  label: AppStrings.source,
                  value: job.source,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============================================
            // CONTACT INFORMATION SECTION
            // ============================================
            _SectionCard(
              title: AppStrings.contactInfo,
              children: [
                _DetailRow(
                  icon: Icons.email,
                  label: AppStrings.contactEmail,
                  value: job.contactEmail,
                  onTap: job.contactEmail != null
                      ? () => _openEmail(context, job.contactEmail!)
                      : null,
                ),
                _DetailRow(
                  icon: Icons.phone,
                  label: AppStrings.contactMethod,
                  value: job.contactMethod,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============================================
            // RESUME & SOURCE SECTION
            // ============================================
            _SectionCard(
              title: AppStrings.resumeAndSource,
              children: [
                _DetailRow(
                  icon: Icons.description,
                  label: AppStrings.cvUsed,
                  value: job.cvUsed,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============================================
            // FOLLOW-UP SECTION
            // ============================================
            _SectionCard(
              title: AppStrings.followUp,
              children: [
                _DetailRow(
                  icon: Icons.notifications_active,
                  label: AppStrings.followUpDate,
                  value: _formatDate(job.followUpDate),
                  isHighlighted: _isFollowUpSoon(job.followUpDate),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ============================================
            // NOTES SECTION
            // ============================================
            if (job.notes != null && job.notes!.isNotEmpty) ...[
              _SectionCard(
                title: AppStrings.notes,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(job.notes!, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ============================================
            // TIMESTAMPS
            // ============================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _TimestampRow(
                      label: 'Created',
                      value: _formatDateTime(job.createdAt),
                    ),
                    const Divider(height: 16),
                    _TimestampRow(
                      label: 'Last Updated',
                      value: _formatDateTime(job.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // ACTION BUTTONS
            // ============================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(AppStrings.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEdit(context),
                    icon: const Icon(Icons.edit),
                    label: const Text(AppStrings.edit),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    } catch (_) {
      return dateString;
    }
  }

  bool _isFollowUpSoon(String? dateString) {
    if (dateString == null) return false;
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      return difference >= 0 && difference <= 3;
    } catch (_) {
      return false;
    }
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      FadeSlidePageRoute(page: JobFormScreen(jobToEdit: job)),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text(
          '${AppStrings.deleteConfirmMessage}\n\nJob: ${job.jobName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<JobsCubit>().deleteJob(job.id);
              Navigator.pop(context); // Go back to home
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

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open link')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ============================================
// STATUS BADGE WIDGET
// ============================================
class _StatusBadge extends StatelessWidget {
  final JobStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getStatusBackgroundColor(status, isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: AppColors.getStatusTextColor(status, isDark),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================
// SECTION CARD WIDGET
// ============================================
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

// ============================================
// ACTION CARD WIDGET
// ============================================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// DETAIL ROW WIDGET
// ============================================
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: hasValue ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isHighlighted
                  ? Colors.orange
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : 'Not specified',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasValue
                          ? (isHighlighted ? Colors.orange : null)
                          : theme.textTheme.bodySmall?.color,
                      fontStyle: hasValue ? null : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && hasValue)
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TIMESTAMP ROW WIDGET
// ============================================
class _TimestampRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimestampRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
