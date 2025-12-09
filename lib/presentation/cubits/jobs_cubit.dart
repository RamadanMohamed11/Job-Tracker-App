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

  const JobsState({
    this.jobs = const [],
    this.filteredJobs = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.sortOption = SortOption.dateNewest,
    this.isLoading = false,
    this.errorMessage,
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
    );
  }

  /// Returns the count of jobs currently displayed
  int get displayedCount => filteredJobs.length;

  /// Returns the total count of all jobs
  int get totalCount => jobs.length;
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
  // SCHEDULE NOTIFICATION HELPER
  // ============================================
  /// Schedules a notification for a job's follow-up date.
  /// Uses the provided hour and minute, or defaults to 9:00 AM.
  void _scheduleNotification(
    JobApplication job, {
    int hour = 9,
    int minute = 0,
  }) {
    if (job.followUpDate == null || job.followUpDate!.isEmpty) return;

    try {
      final followUpDateTime = DateTime.parse(job.followUpDate!);
      NotificationService().scheduleFollowUpNotification(
        jobId: job.id,
        jobName: job.jobName,
        companyName: job.companyName,
        followUpDate: followUpDateTime,
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      // Silently fail if date parsing fails
      // The notification just won't be scheduled
    }
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
  // SORT
  // ============================================
  /// Sets the sort option.
  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
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
