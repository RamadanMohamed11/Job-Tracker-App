import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/notification_service.dart';
import '../../data/data.dart';
import '../../core/constants/status_options.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// JobsCubit manages all job-related state:
// - List of all jobs
// - Current search query
// - Current filter (by status)
// - Current sort order
// - Loading and error states
//
// The UI listens to this Cubit and rebuilds when state changes.

// ============================================
// DASHBOARD FILTER OPTIONS
// ============================================
// Used to filter jobs by clicking on dashboard cards
enum DashboardFilter {
  none, // Show all jobs
  totalJobs, // Show all jobs
  interviews, // Show interview-related jobs
  followUps, // Show jobs with pending follow-ups
  successful, // Show offers and accepted jobs
}

// ============================================
// JOBS STATE
// ============================================
// Holds all the data the UI needs to display jobs.
class JobsState {
  final List<JobApplication> jobs;
  final List<JobApplication> filteredJobs;
  final String searchQuery;
  final JobStatus? statusFilter;
  final SortOption sortOption;
  final bool isLoading;
  final String? errorMessage;
  // Selection mode fields
  final bool isSelectionMode;
  final Set<String> selectedJobIds;
  // Dashboard filter
  final DashboardFilter dashboardFilter;

  const JobsState({
    this.jobs = const [],
    this.filteredJobs = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.sortOption = SortOption.dateNewest,
    this.isLoading = false,
    this.errorMessage,
    this.isSelectionMode = false,
    this.selectedJobIds = const {},
    this.dashboardFilter = DashboardFilter.totalJobs,
  });

  // Create a copy with different values
  JobsState copyWith({
    List<JobApplication>? jobs,
    List<JobApplication>? filteredJobs,
    String? searchQuery,
    JobStatus? statusFilter,
    bool clearStatusFilter = false,
    SortOption? sortOption,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSelectionMode,
    Set<String>? selectedJobIds,
    DashboardFilter? dashboardFilter,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      filteredJobs: filteredJobs ?? this.filteredJobs,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      sortOption: sortOption ?? this.sortOption,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedJobIds: selectedJobIds ?? this.selectedJobIds,
      dashboardFilter: dashboardFilter ?? this.dashboardFilter,
    );
  }

  /// Returns the count of jobs currently displayed
  int get displayedCount => filteredJobs.length;

  /// Returns the total count of all jobs
  int get totalCount => jobs.length;

  /// Returns the count of selected jobs
  int get selectedCount => selectedJobIds.length;

  /// Check if a job is selected
  bool isSelected(String jobId) => selectedJobIds.contains(jobId);
}

// ============================================
// JOBS CUBIT
// ============================================
class JobsCubit extends Cubit<JobsState> {
  final JobRepository _repository;

  JobsCubit({JobRepository? repository})
    : _repository = repository ?? JobRepository(),
      super(const JobsState());

  // ============================================
  // LOAD JOBS
  // ============================================
  /// Loads all jobs from the database and applies current filters/sort.
  /// Call this when the app starts or after adding/editing/deleting.
  void loadJobs() {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final allJobs = _repository.getAllJobs();
      emit(state.copyWith(jobs: allJobs, isLoading: false));
      _applyFiltersAndSort();
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load jobs: $e',
        ),
      );
    }
  }

  // ============================================
  // DUPLICATE DETECTION
  // ============================================
  /// Checks if a similar job exists based on job name and company name.
  /// Returns a list of potential duplicate jobs.
  /// [excludeJobId] - exclude this job ID when editing an existing job.
  List<JobApplication> findDuplicates({
    required String jobName,
    String? companyName,
    String? excludeJobId,
  }) {
    if (jobName.isEmpty) return [];

    final normalizedJobName = _normalize(jobName);
    final normalizedCompany = companyName != null
        ? _normalize(companyName)
        : null;

    return state.jobs.where((job) {
      // Skip the job being edited
      if (excludeJobId != null && job.id == excludeJobId) return false;

      final existingJobName = _normalize(job.jobName);
      final existingCompany = job.companyName != null
          ? _normalize(job.companyName!)
          : null;

      // Check for similar job name
      final nameSimilar = _isSimilar(normalizedJobName, existingJobName);

      // If company names are provided, check for match
      if (normalizedCompany != null &&
          normalizedCompany.isNotEmpty &&
          existingCompany != null &&
          existingCompany.isNotEmpty) {
        final companySimilar = _isSimilar(normalizedCompany, existingCompany);
        // Both name and company are similar
        return nameSimilar && companySimilar;
      }

      // Just check job name similarity (more strict without company context)
      return existingJobName == normalizedJobName;
    }).toList();
  }

  /// Normalizes a string for comparison (lowercase, trimmed, remove extra spaces).
  String _normalize(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Checks if two strings are similar (exact match or one contains the other).
  bool _isSimilar(String a, String b) {
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;
    // Check for common abbreviations
    if (_levenshteinDistance(a, b) <= 3 && a.length > 5 && b.length > 5) {
      return true;
    }
    return false;
  }

  /// Simple Levenshtein distance for fuzzy matching.
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List.generate(b.length + 1, (i) => i);
    List<int> currentRow = List.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        int insertCost = currentRow[j] + 1;
        int deleteCost = previousRow[j + 1] + 1;
        int replaceCost = a[i] == b[j] ? previousRow[j] : previousRow[j] + 1;
        currentRow[j + 1] = [
          insertCost,
          deleteCost,
          replaceCost,
        ].reduce((a, b) => a < b ? a : b);
      }
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }
    return previousRow[b.length];
  }

  // ============================================
  // ADD JOB
  // ============================================
  /// Adds a new job application to the database.
  /// [notificationHour] and [notificationMinute] specify when to show the reminder.
  Future<JobApplication?> addJob({
    required String jobName,
    String? companyName,
    String? jobLink,
    String? contactMethod,
    String? cvUsed,
    String? notes,
    String? followUpDate,
    String? source,
    String? contactEmail,
    String? applicationDate,
    JobStatus? status,
    int notificationHour = 9,
    int notificationMinute = 0,
  }) async {
    try {
      final job = await _repository.addJob(
        jobName: jobName,
        companyName: companyName,
        jobLink: jobLink,
        contactMethod: contactMethod,
        cvUsed: cvUsed,
        notes: notes,
        followUpDate: followUpDate,
        source: source,
        contactEmail: contactEmail,
        applicationDate: applicationDate,
        status: status,
      );

      // Schedule notification if follow-up date is set
      if (followUpDate != null && followUpDate.isNotEmpty) {
        _scheduleNotification(
          job,
          hour: notificationHour,
          minute: notificationMinute,
        );
      }

      loadJobs(); // Refresh the list
      return job;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to add job: $e'));
      return null;
    }
  }

  // ============================================
  // UPDATE JOB
  // ============================================
  /// Updates an existing job application.
  /// [notificationHour] and [notificationMinute] specify when to show the reminder.
  Future<JobApplication?> updateJob({
    required String id,
    String? jobName,
    String? companyName,
    String? jobLink,
    String? contactMethod,
    String? cvUsed,
    String? notes,
    String? followUpDate,
    String? source,
    String? contactEmail,
    String? applicationDate,
    JobStatus? status,
    int notificationHour = 9,
    int notificationMinute = 0,
  }) async {
    try {
      final job = await _repository.updateJob(
        id: id,
        jobName: jobName,
        companyName: companyName,
        jobLink: jobLink,
        contactMethod: contactMethod,
        cvUsed: cvUsed,
        notes: notes,
        followUpDate: followUpDate,
        source: source,
        contactEmail: contactEmail,
        applicationDate: applicationDate,
        status: status,
      );
      if (job != null) {
        // Cancel old notification and schedule new one if follow-up date exists
        await NotificationService().cancelNotification(id);
        if (job.followUpDate != null && job.followUpDate!.isNotEmpty) {
          _scheduleNotification(
            job,
            hour: notificationHour,
            minute: notificationMinute,
          );
        }
        loadJobs(); // Refresh the list
      }
      return job;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update job: $e'));
      return null;
    }
  }

  // ============================================
  // DELETE JOB
  // ============================================
  /// Deletes a job application from the database.
  Future<bool> deleteJob(String id) async {
    try {
      // Cancel any scheduled notification for this job
      await NotificationService().cancelNotification(id);

      final deleted = await _repository.deleteJob(id);
      if (deleted) {
        loadJobs(); // Refresh the list
      }
      return deleted;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete job: $e'));
      return false;
    }
  }

  // ============================================
  // SELECTION MODE
  // ============================================
  /// Enters selection mode (long press on a job card)
  void enterSelectionMode(String initialJobId) {
    emit(state.copyWith(isSelectionMode: true, selectedJobIds: {initialJobId}));
  }

  /// Exits selection mode and clears selection
  void exitSelectionMode() {
    emit(state.copyWith(isSelectionMode: false, selectedJobIds: const {}));
  }

  /// Toggles selection of a job
  void toggleJobSelection(String jobId) {
    final newSelection = Set<String>.from(state.selectedJobIds);
    if (newSelection.contains(jobId)) {
      newSelection.remove(jobId);
      // Exit selection mode if no jobs selected
      if (newSelection.isEmpty) {
        exitSelectionMode();
        return;
      }
    } else {
      newSelection.add(jobId);
    }
    emit(state.copyWith(selectedJobIds: newSelection));
  }

  /// Selects all jobs in the filtered list
  void selectAllJobs() {
    final allIds = state.filteredJobs.map((job) => job.id).toSet();
    emit(state.copyWith(selectedJobIds: allIds));
  }

  /// Deletes all selected jobs
  Future<void> deleteSelectedJobs() async {
    if (state.selectedJobIds.isEmpty) return;

    try {
      emit(state.copyWith(isLoading: true));

      // Cancel notifications and delete each selected job
      for (final jobId in state.selectedJobIds) {
        await NotificationService().cancelNotification(jobId);
        await _repository.deleteJob(jobId);
      }

      // Exit selection mode and refresh
      emit(
        state.copyWith(
          isSelectionMode: false,
          selectedJobIds: const {},
          isLoading: false,
        ),
      );
      loadJobs();
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to delete jobs: $e',
          isLoading: false,
        ),
      );
    }
  }

  // ============================================
  // SCHEDULE NOTIFICATION HELPER
  // ============================================
  /// Schedules a notification for a job's follow-up date.
  /// Uses the provided hour and minute, or defaults to 9:00 AM.
  Future<void> _scheduleNotification(
    JobApplication job, {
    int hour = 9,
    int minute = 0,
  }) async {
    debugPrint('_scheduleNotification called for job: ${job.jobName}');
    debugPrint('  followUpDate: ${job.followUpDate}');
    debugPrint('  hour: $hour, minute: $minute');

    if (job.followUpDate == null || job.followUpDate!.isEmpty) {
      debugPrint('  ⚠️ No follow-up date, skipping notification');
      return;
    }

    try {
      final followUpDateTime = DateTime.parse(job.followUpDate!);
      debugPrint('  Parsed follow-up date: $followUpDateTime');

      await NotificationService().scheduleFollowUpNotification(
        jobId: job.id,
        jobName: job.jobName,
        companyName: job.companyName,
        followUpDate: followUpDateTime,
        hour: hour,
        minute: minute,
      );
      debugPrint('  ✅ Notification service call completed');
    } catch (e, stack) {
      debugPrint('  ❌ Error in _scheduleNotification: $e');
      debugPrint('  Stack: $stack');
    }
  }

  // ============================================
  // RESCHEDULE ALL NOTIFICATIONS
  // ============================================
  /// Reschedules notifications for all jobs with follow-up dates.
  /// Call this when the notification time setting is changed.
  Future<void> rescheduleAllNotifications({
    required int hour,
    required int minute,
  }) async {
    debugPrint(
      'rescheduleAllNotifications called with hour: $hour, minute: $minute',
    );

    int scheduledCount = 0;
    int skippedCount = 0;

    for (final job in state.jobs) {
      if (job.followUpDate != null && job.followUpDate!.isNotEmpty) {
        // Cancel existing notification
        await NotificationService().cancelNotification(job.id);

        // Schedule new notification with updated time
        await _scheduleNotification(job, hour: hour, minute: minute);
        scheduledCount++;
      } else {
        skippedCount++;
      }
    }

    debugPrint(
      '✅ Rescheduled $scheduledCount notifications, skipped $skippedCount jobs without follow-up dates',
    );
  }

  // ============================================
  // SEARCH
  // ============================================
  /// Sets the search query and filters the list.
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFiltersAndSort();
  }

  /// Clears the search query.
  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
    _applyFiltersAndSort();
  }

  // ============================================
  // FILTER BY STATUS
  // ============================================
  /// Sets the status filter.
  void setStatusFilter(JobStatus? status) {
    if (status == null) {
      emit(state.copyWith(clearStatusFilter: true));
    } else {
      emit(state.copyWith(statusFilter: status));
    }
    _applyFiltersAndSort();
  }

  /// Clears the status filter (show all statuses).
  void clearStatusFilter() {
    emit(state.copyWith(clearStatusFilter: true));
    _applyFiltersAndSort();
  }

  // ============================================
  /// Sets the sort option.
  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
    _applyFiltersAndSort();
  }

  // ============================================
  // DASHBOARD FILTER
  // ============================================
  /// Sets the dashboard filter (click on a dashboard card).
  void setDashboardFilter(DashboardFilter filter) {
    // If clicking the same filter, toggle it off
    if (state.dashboardFilter == filter && filter != DashboardFilter.none) {
      emit(state.copyWith(dashboardFilter: DashboardFilter.none));
    } else {
      emit(state.copyWith(dashboardFilter: filter));
    }
    _applyFiltersAndSort();
  }

  /// Clears the dashboard filter.
  void clearDashboardFilter() {
    emit(state.copyWith(dashboardFilter: DashboardFilter.none));
    _applyFiltersAndSort();
  }

  // ============================================
  // APPLY FILTERS AND SORT
  // ============================================
  /// Internal method that applies search, filter, and sort to the jobs list.
  void _applyFiltersAndSort() {
    List<JobApplication> result;

    // Apply search filter using repository method (reuse, don't duplicate!)
    if (state.searchQuery.isNotEmpty) {
      result = _repository.searchJobs(state.searchQuery);
    } else {
      result = List<JobApplication>.from(state.jobs);
    }

    // Apply status filter
    if (state.statusFilter != null) {
      result = result
          .where((job) => job.statusEnum == state.statusFilter)
          .toList();
    }

    // Apply dashboard filter
    final now = DateTime.now();
    switch (state.dashboardFilter) {
      case DashboardFilter.none:
      case DashboardFilter.totalJobs:
        // Show all jobs
        break;
      case DashboardFilter.interviews:
        // Show interview-related jobs
        result = result
            .where(
              (job) =>
                  job.statusEnum == JobStatus.interviewScheduled ||
                  job.statusEnum == JobStatus.interviewed,
            )
            .toList();
        break;
      case DashboardFilter.followUps:
        // Show jobs with pending follow-ups
        result = result.where((job) {
          if (job.followUpDate == null || job.followUpDate!.isEmpty) {
            return false;
          }
          try {
            final followUpDate = DateTime.parse(job.followUpDate!);
            return followUpDate.isAfter(now) ||
                (followUpDate.year == now.year &&
                    followUpDate.month == now.month &&
                    followUpDate.day == now.day);
          } catch (_) {
            return false;
          }
        }).toList();
        break;
      case DashboardFilter.successful:
        // Show offers and accepted jobs
        result = result
            .where(
              (job) =>
                  job.statusEnum == JobStatus.offerReceived ||
                  job.statusEnum == JobStatus.accepted,
            )
            .toList();
        break;
    }

    // Apply sort
    switch (state.sortOption) {
      case SortOption.dateNewest:
        result = _repository.sortByDate(result, newestFirst: true);
        break;
      case SortOption.dateOldest:
        result = _repository.sortByDate(result, newestFirst: false);
        break;
      case SortOption.nameAZ:
        result = _repository.sortByName(result, ascending: true);
        break;
      case SortOption.nameZA:
        result = _repository.sortByName(result, ascending: false);
        break;
    }

    emit(state.copyWith(filteredJobs: result));
  }

  // ============================================
  // GET JOB BY ID
  // ============================================
  /// Returns a single job by its ID.
  JobApplication? getJobById(String id) {
    return _repository.getJobById(id);
  }

  // ============================================
  // CLEAR ERROR
  // ============================================
  /// Clears any error message.
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
