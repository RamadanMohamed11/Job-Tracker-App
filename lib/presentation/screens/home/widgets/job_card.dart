import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../data/models/job_application.dart';

// ============================================
// JOB CARD WIDGET
// ============================================
// Displays a single job application as a card.
// Features:
// - Job name and company
// - Status badge with color coding
// - Application date
// - Source badge
// - Swipe actions (edit, delete)

class JobCard extends StatelessWidget {
  final JobApplication job;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        // ============================================
        // SLIDE ACTIONS (Swipe left to reveal)
        // ============================================
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.4,
          children: [
            // Edit action
            SlidableAction(
              onPressed: (_) => onEdit?.call(),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: AppStrings.edit,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            // Delete action
            SlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: AppStrings.delete,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),

        // ============================================
        // CARD CONTENT
        // ============================================
        child: Card(
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Job name and status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job name (expanded to take available space)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.jobName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (job.companyName != null &&
                                job.companyName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                job.companyName!,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status badge
                      _StatusBadge(status: job.statusEnum, isDark: isDark),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Info row: Date and source
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      // Application date
                      if (job.applicationDate != null) ...[
                        _InfoChip(
                          icon: Icons.calendar_today,
                          label: _formatDate(job.applicationDate!),
                        ),
                      ],
                      // Source
                      if (job.source != null && job.source!.isNotEmpty) ...[
                        _InfoChip(icon: Icons.source, label: job.source!),
                      ],
                      // Follow-up date
                      if (job.followUpDate != null) ...[
                        _InfoChip(
                          icon: Icons.notifications_active,
                          label: 'Follow: ${_formatDate(job.followUpDate!)}',
                          isWarning: _isFollowUpSoon(job.followUpDate!),
                        ),
                      ],
                    ],
                  ),

                  // Notes preview (if exists)
                  if (job.notes != null && job.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      job.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Format date string to readable format
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  // Check if follow-up date is within 3 days
  bool _isFollowUpSoon(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      return difference >= 0 && difference <= 3;
    } catch (_) {
      return false;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getStatusBackgroundColor(status, isDark),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: AppColors.getStatusTextColor(status, isDark),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================
// INFO CHIP WIDGET
// ============================================
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isWarning;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isWarning ? Colors.orange : theme.textTheme.bodySmall?.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
