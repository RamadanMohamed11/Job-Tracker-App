import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

// ============================================
// EMPTY STATE WIDGET
// ============================================
// Displayed when there are no jobs to show.
// Two variants:
// 1. No jobs at all - encourage adding first job
// 2. No matching results - offer to clear filters

class EmptyStateWidget extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  const EmptyStateWidget({
    super.key,
    this.hasFilters = false,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            // Icon
            Icon(
              hasFilters ? Icons.search_off : Icons.work_off_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              hasFilters ? AppStrings.noJobsFound : 'No Jobs Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Tap the + button below to add your first job application',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            // Clear filters button (only if filters are active)
            if (hasFilters && onClearFilters != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
