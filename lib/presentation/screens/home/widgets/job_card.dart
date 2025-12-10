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
// - Long press to enter selection mode

class JobCard extends StatelessWidget {
  final JobApplication job;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Disable slidable when edit/delete are null (selection mode)
    final hasSlideActions = onEdit != null || onDelete != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: hasSlideActions
          ? Slidable(
              // ============================================
              // SLIDE LEFT ACTIONS (Swipe right to reveal) - Archive
              // ============================================
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.35,
                children: [
                  SlidableAction(
                    onPressed: (_) => onArchive?.call(),
                    backgroundColor: job.isArchived
                        ? Colors.teal
                        : Colors.blueGrey,
                    foregroundColor: Colors.white,
                    icon: job.isArchived ? Icons.unarchive : Icons.archive,
                    label: job.isArchived ? 'Unarchive' : 'Archive',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),

              // ============================================
              // SLIDE RIGHT ACTIONS (Swipe left to reveal)
              // ============================================
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.85,
                children: [
                  // Pin action
                  SlidableAction(
                    onPressed: (_) => onPin?.call(),
                    backgroundColor: job.isPinned ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    icon: job.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin,
                    label: job.isPinned ? 'Unpin' : 'Pin',
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                  // Edit action
                  SlidableAction(
                    onPressed: (_) => onEdit?.call(),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: AppStrings.edit,
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
              child: _buildCard(context, theme, isDark),
            )
          : _buildCard(context, theme, isDark),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                        Row(
                          children: [
                            // Pinned indicator
                            if (job.isPinned) ...[
                              Icon(
                                Icons.push_pin,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            // Archived indicator
                            if (job.isArchived) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blueGrey,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.archive,
                                      size: 12,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Archived',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.blueGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                job.jobName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: job.isArchived
                                      ? Colors.blueGrey
                                      : theme.colorScheme.primary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                    _InfoChip(
                      icon: _getSourceIcon(job.source!),
                      label: job.source!,
                    ),
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

              // Tags display
              if (job.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: job.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTagColor(tag),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getTagColor(tag),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

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

  // Get color for a tag based on its name
  Color _getTagColor(String tag) {
    final tagLower = tag.toLowerCase();
    if (tagLower.contains('remote')) return Colors.blue;
    if (tagLower.contains('hybrid')) return Colors.teal;
    if (tagLower.contains('on-site') || tagLower.contains('onsite')) {
      return Colors.orange;
    }
    if (tagLower.contains('urgent')) return Colors.red;
    if (tagLower.contains('dream')) return Colors.purple;
    if (tagLower.contains('referral')) return Colors.green;
    // Default color based on hash
    final colors = [
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.lime,
    ];
    return colors[tag.hashCode.abs() % colors.length];
  }

  // Get icon for job source
  IconData _getSourceIcon(String source) {
    final sourceLower = source.toLowerCase();
    if (sourceLower.contains('linkedin')) return Icons.business_center;
    if (sourceLower.contains('indeed')) return Icons.search;
    if (sourceLower.contains('wuzzuf')) return Icons.work;
    if (sourceLower.contains('glassdoor')) return Icons.door_front_door;
    if (sourceLower.contains('bayt')) return Icons.home_work;
    if (sourceLower.contains('whatsapp')) return Icons.chat;
    if (sourceLower.contains('company') || sourceLower.contains('website')) {
      return Icons.language;
    }
    if (sourceLower.contains('referral')) return Icons.people;
    if (sourceLower.contains('recruiter')) return Icons.person_search;
    if (sourceLower.contains('github')) return Icons.code;
    if (sourceLower.contains('stack overflow')) return Icons.layers;
    if (sourceLower.contains('twitter') || sourceLower.contains('x')) {
      return Icons.alternate_email;
    }
    return Icons.source; // Default
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
