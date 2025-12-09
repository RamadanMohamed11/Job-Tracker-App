import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../cubits/jobs_cubit.dart';

// ============================================
// FILTER & SORT BAR WIDGET
// ============================================
// Horizontal row with dropdown menus for:
// - Filter by status
// - Sort by (date, name)

class FilterSortBar extends StatelessWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter by status dropdown
          Expanded(child: _StatusFilterDropdown()),
          const SizedBox(width: 12),
          // Sort dropdown
          Expanded(child: _SortDropdown()),
        ],
      ),
    );
  }
}

// ============================================
// STATUS FILTER DROPDOWN
// ============================================
class _StatusFilterDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<JobsCubit, JobsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerTheme.color ?? Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<JobStatus?>(
              value: state.statusFilter,
              isExpanded: true,
              hint: const Text(AppStrings.allStatuses),
              icon: const Icon(Icons.filter_list),
              items: [
                // "All" option
                const DropdownMenuItem<JobStatus?>(
                  value: null,
                  child: Text(AppStrings.allStatuses),
                ),
                // Status options
                ...JobStatus.values.map((status) {
                  return DropdownMenuItem<JobStatus?>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }),
              ],
              onChanged: (value) {
                context.read<JobsCubit>().setStatusFilter(value);
              },
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// SORT DROPDOWN
// ============================================
class _SortDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<JobsCubit, JobsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerTheme.color ?? Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SortOption>(
              value: state.sortOption,
              isExpanded: true,
              icon: const Icon(Icons.sort),
              items: SortOption.values.map((option) {
                return DropdownMenuItem<SortOption>(
                  value: option,
                  child: Text(option.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  context.read<JobsCubit>().setSortOption(value);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
