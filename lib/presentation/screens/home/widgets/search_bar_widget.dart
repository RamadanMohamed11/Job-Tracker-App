import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../cubits/jobs_cubit.dart';

// ============================================
// SEARCH BAR WIDGET
// ============================================
// A search input field that filters jobs by name, company, or email.
// Uses debouncing to avoid excessive filtering while typing.

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          // Clear button - only show when there's text
          suffixIcon: BlocBuilder<JobsCubit, JobsState>(
            builder: (context, state) {
              if (state.searchQuery.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    context.read<JobsCubit>().clearSearch();
                    _focusNode.unfocus();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Make it look like a search bar
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          // Update search query as user types
          context.read<JobsCubit>().setSearchQuery(value);
        },
        onSubmitted: (_) {
          _focusNode.unfocus();
        },
      ),
    );
  }
}
