import 'package:uuid/uuid.dart';
import '../local/database_service.dart';
import '../models/job_application.dart';
import '../../core/constants/status_options.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// The JobRepository is the "bridge" between the UI and the database.
// It provides clean methods for CRUD operations:
// - Create (add new job)
// - Read (get all jobs, get one job)
// - Update (modify a job)
// - Delete (remove a job)
//
// The UI never talks directly to Hive - it goes through this repository.
// This makes the code easier to test and maintain.

class JobRepository {
  // ============================================
  // DEPENDENCIES
  // ============================================
  // We need access to the database service to interact with Hive
  final DatabaseService _databaseService;

  // UUID generator for creating unique IDs
  final Uuid _uuid = const Uuid();

  // Constructor - receives the database service
  // This is called "dependency injection" - we pass in what we need
  JobRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  // ============================================
  // CREATE - Add a new job
  // ============================================
  /// Adds a new job application to the database.
  ///
  /// [jobName] - Required, the name of the job position
  /// All other parameters are optional.
  ///
  /// Returns the created JobApplication with a generated ID.
  ///
  /// Example:
  /// ```dart
  /// final job = await jobRepo.addJob(
  ///   jobName: 'Flutter Developer',
  ///   companyName: 'Google',
  ///   status: JobStatus.applied,
  /// );
  /// ```
  Future<JobApplication> addJob({
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
    String? interviewDate,
  }) async {
    // Generate a unique ID for this job
    final id = _uuid.v4();

    // Get the current timestamp
    final now = DateTime.now().toIso8601String();

    // Create the JobApplication object
    final job = JobApplication(
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
      status: status?.displayName, // Convert enum to string
      createdAt: now,
      updatedAt: now,
      interviewDate: interviewDate,
    );

    // Save to database
    // We use the ID as the key, so we can find it easily later
    await _databaseService.jobsBox.put(id, job);

    return job;
  }

  // ============================================
  // READ - Get all jobs
  // ============================================
  /// Returns all job applications from the database.
  ///
  /// Example:
  /// ```dart
  /// final jobs = jobRepo.getAllJobs();
  /// print('You have ${jobs.length} job applications');
  /// ```
  List<JobApplication> getAllJobs() {
    // .values returns all objects in the box as an Iterable
    // .toList() converts it to a List
    return _databaseService.jobsBox.values.toList();
  }

  // ============================================
  // READ - Get one job by ID
  // ============================================
  /// Returns a single job application by its ID.
  /// Returns null if no job is found with that ID.
  ///
  /// Example:
  /// ```dart
  /// final job = jobRepo.getJobById('abc-123');
  /// if (job != null) {
  ///   print('Found: ${job.jobName}');
  /// }
  /// ```
  JobApplication? getJobById(String id) {
    return _databaseService.jobsBox.get(id);
  }

  // ============================================
  // UPDATE - Modify a job
  // ============================================
  /// Updates an existing job application.
  ///
  /// [id] - The ID of the job to update
  /// Pass any fields you want to change.
  /// Fields you don't pass will keep their current values.
  ///
  /// Returns the updated JobApplication, or null if job not found.
  ///
  /// Example:
  /// ```dart
  /// final updated = await jobRepo.updateJob(
  ///   id: 'abc-123',
  ///   status: JobStatus.interviewed,
  ///   notes: 'Interview went great!',
  /// );
  /// ```
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
    String? interviewDate,
  }) async {
    // First, find the existing job
    final existingJob = _databaseService.jobsBox.get(id);

    // If job doesn't exist, return null
    if (existingJob == null) {
      return null;
    }

    // Create updated job using copyWith
    // This keeps all existing values and only changes what we pass in
    final updatedJob = existingJob.copyWith(
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
      status: status?.displayName,
      interviewDate: interviewDate,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Save the updated job (overwrites the old one)
    await _databaseService.jobsBox.put(id, updatedJob);

    return updatedJob;
  }

  // ============================================
  // DELETE - Remove a job
  // ============================================
  /// Deletes a job application from the database.
  ///
  /// [id] - The ID of the job to delete
  ///
  /// Returns true if deleted, false if job wasn't found.
  ///
  /// Example:
  /// ```dart
  /// final deleted = await jobRepo.deleteJob('abc-123');
  /// if (deleted) {
  ///   print('Job deleted successfully');
  /// }
  /// ```
  Future<bool> deleteJob(String id) async {
    // Check if job exists
    if (!_databaseService.jobsBox.containsKey(id)) {
      return false;
    }

    // Delete from database
    await _databaseService.jobsBox.delete(id);
    return true;
  }

  // ============================================
  // SEARCH & FILTER METHODS
  // ============================================

  /// Search jobs by name or company name
  ///
  /// [query] - The search text
  /// Returns jobs where jobName or companyName contains the query.
  List<JobApplication> searchJobs(String query) {
    if (query.isEmpty) {
      return getAllJobs();
    }

    final lowerQuery = query.toLowerCase();
    return getAllJobs().where((job) {
      final nameMatch = job.jobName.toLowerCase().contains(lowerQuery);
      final companyMatch =
          job.companyName?.toLowerCase().contains(lowerQuery) ?? false;
      final contactEmailMatch =
          job.contactEmail?.toLowerCase().contains(lowerQuery) ?? false;
      return nameMatch || companyMatch || contactEmailMatch;
    }).toList();
  }

  /// Filter jobs by status
  ///
  /// [status] - The status to filter by
  /// Returns only jobs with the matching status.
  List<JobApplication> getJobsByStatus(JobStatus status) {
    return getAllJobs().where((job) {
      return job.statusEnum == status;
    }).toList();
  }

  /// Sort jobs by date (newest first or oldest first)
  ///
  /// [jobs] - The list of jobs to sort
  /// [newestFirst] - If true, newest jobs first. If false, oldest first.
  List<JobApplication> sortByDate(
    List<JobApplication> jobs, {
    bool newestFirst = true,
  }) {
    final sorted = List<JobApplication>.from(jobs);
    sorted.sort((a, b) {
      final dateA = a.applicationDate ?? a.createdAt;
      final dateB = b.applicationDate ?? b.createdAt;
      return newestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    return sorted;
  }

  /// Sort jobs by name (A-Z or Z-A)
  ///
  /// [jobs] - The list of jobs to sort
  /// [ascending] - If true, A-Z. If false, Z-A.
  List<JobApplication> sortByName(
    List<JobApplication> jobs, {
    bool ascending = true,
  }) {
    final sorted = List<JobApplication>.from(jobs);
    sorted.sort((a, b) {
      return ascending
          ? a.jobName.toLowerCase().compareTo(b.jobName.toLowerCase())
          : b.jobName.toLowerCase().compareTo(a.jobName.toLowerCase());
    });
    return sorted;
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Returns the total count of job applications
  int get totalCount => _databaseService.jobsBox.length;

  /// Returns count of jobs grouped by status
  Map<JobStatus, int> getStatusCounts() {
    final jobs = getAllJobs();
    final counts = <JobStatus, int>{};

    for (final status in JobStatus.values) {
      counts[status] = jobs.where((job) => job.statusEnum == status).length;
    }

    return counts;
  }

  // ============================================
  // TOGGLE PIN STATUS
  // ============================================
  /// Toggles the pinned status of a job.
  /// Returns the updated job, or null if job not found.
  Future<JobApplication?> togglePin(String id) async {
    final existingJob = _databaseService.jobsBox.get(id);

    if (existingJob == null) {
      return null;
    }

    final updatedJob = existingJob.copyWith(
      isPinned: !existingJob.isPinned,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _databaseService.jobsBox.put(id, updatedJob);
    return updatedJob;
  }

  // ============================================
  // SORT WITH PINNED FIRST
  // ============================================
  /// Takes a sorted list and moves pinned items to the top
  /// while maintaining their relative order.
  List<JobApplication> sortWithPinnedFirst(List<JobApplication> jobs) {
    final pinned = jobs.where((j) => j.isPinned).toList();
    final unpinned = jobs.where((j) => !j.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  // ============================================
  // TOGGLE ARCHIVE STATUS
  // ============================================
  /// Toggles the archived status of a job.
  /// Returns the updated job, or null if job not found.
  Future<JobApplication?> toggleArchive(String id) async {
    final existingJob = _databaseService.jobsBox.get(id);

    if (existingJob == null) {
      return null;
    }

    final updatedJob = existingJob.copyWith(
      isArchived: !existingJob.isArchived,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await _databaseService.jobsBox.put(id, updatedJob);
    return updatedJob;
  }

  // ============================================
  // GET ACTIVE JOBS (NOT ARCHIVED)
  // ============================================
  /// Returns all jobs that are NOT archived.
  List<JobApplication> getActiveJobs() {
    return getAllJobs().where((job) => !job.isArchived).toList();
  }

  // ============================================
  // GET ARCHIVED JOBS
  // ============================================
  /// Returns all jobs that ARE archived.
  List<JobApplication> getArchivedJobs() {
    return getAllJobs().where((job) => job.isArchived).toList();
  }
}
