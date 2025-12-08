import 'package:hive/hive.dart';
import '../../core/constants/status_options.dart';

// ============================================
// WHAT IS THIS FILE?
// ============================================
// This is the "JobApplication" model - a class that represents
// a single job application. Think of it like a form with fields
// that holds all the information about one job you applied to.
//
// The @HiveType and @HiveField annotations tell Hive how to
// save and load this object from the local database.

// This line tells the code generator to create a file called
// "job_application.g.dart" with the adapter code.
part 'job_application.g.dart';

// ============================================
// @HiveType ANNOTATION
// ============================================
// This marks the class as a Hive object that can be stored.
// typeId: A unique number for this type (0-223).
// Each model class needs a different typeId.
// If you add more models later, use typeId: 1, typeId: 2, etc.
@HiveType(typeId: 0)
class JobApplication extends HiveObject {
  // ============================================
  // @HiveField ANNOTATION
  // ============================================
  // Each field that should be saved needs @HiveField(index)
  // The index is a unique number for each field (0, 1, 2, ...)
  // IMPORTANT: Never change the index once data is saved!
  // If you add new fields later, use the next available index.

  /// Unique identifier for this job application
  /// Generated automatically using UUID
  @HiveField(0)
  final String id;

  /// Name/title of the job position (REQUIRED)
  /// Example: "Flutter Developer", "Senior Software Engineer"
  @HiveField(1)
  final String jobName;

  /// Name of the company (optional)
  /// Example: "Google", "Microsoft"
  @HiveField(2)
  final String? companyName;

  /// URL link to the job posting (optional)
  /// Example: "https://linkedin.com/jobs/12345"
  @HiveField(3)
  final String? jobLink;

  /// How you contacted or how to contact (optional)
  /// Example: "Email", "LinkedIn DM", "Phone"
  @HiveField(4)
  final String? contactMethod;

  /// Which CV/Resume was used for this application (optional)
  /// Example: "Flutter_CV_2024.pdf", "General Resume"
  @HiveField(5)
  final String? cvUsed;

  /// Additional notes about this job (optional)
  /// Example: "Great company culture, remote friendly"
  @HiveField(6)
  final String? notes;

  /// Date to follow up on this application (optional)
  /// Stored as ISO string "2024-12-15" for easy serialization
  @HiveField(7)
  final String? followUpDate;

  /// Where you found this job (optional)
  /// Example: "LinkedIn", "Indeed", "Referral"
  @HiveField(8)
  final String? source;

  /// Contact person's email address (optional)
  /// Example: "recruiter@company.com"
  @HiveField(9)
  final String? contactEmail;

  /// Date when you applied (optional)
  /// Stored as ISO string "2024-12-09"
  @HiveField(10)
  final String? applicationDate;

  /// Current status of the application (optional)
  /// Stored as string, converted to/from JobStatus enum
  @HiveField(11)
  final String? status;

  /// When this entry was created (auto-generated)
  @HiveField(12)
  final String createdAt;

  /// When this entry was last updated (auto-generated)
  @HiveField(13)
  final String updatedAt;

  // ============================================
  // CONSTRUCTOR
  // ============================================
  // Creates a new JobApplication instance.
  // Only 'id', 'jobName', 'createdAt', and 'updatedAt' are required.
  // All other fields are optional (nullable).
  JobApplication({
    required this.id,
    required this.jobName,
    this.companyName,
    this.jobLink,
    this.contactMethod,
    this.cvUsed,
    this.notes,
    this.followUpDate,
    this.source,
    this.contactEmail,
    this.applicationDate,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================
  // HELPER GETTERS
  // ============================================

  /// Converts the status string to JobStatus enum
  /// Returns JobStatus.applied if status is null or invalid
  JobStatus get statusEnum {
    if (status == null) return JobStatus.applied;
    return JobStatusExtension.fromString(status!);
  }

  /// Returns the display name for the status
  String get statusDisplayName => statusEnum.displayName;

  // ============================================
  // copyWith METHOD
  // ============================================
  // Creates a copy of this object with some fields changed.
  // This is useful for updating a job without modifying the original.
  //
  // Example:
  //   final updated = job.copyWith(status: 'Interviewed');
  //   // Now 'updated' has the new status, 'job' is unchanged
  JobApplication copyWith({
    String? id,
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
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobName: jobName ?? this.jobName,
      companyName: companyName ?? this.companyName,
      jobLink: jobLink ?? this.jobLink,
      contactMethod: contactMethod ?? this.contactMethod,
      cvUsed: cvUsed ?? this.cvUsed,
      notes: notes ?? this.notes,
      followUpDate: followUpDate ?? this.followUpDate,
      source: source ?? this.source,
      contactEmail: contactEmail ?? this.contactEmail,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  // ============================================
  // toMap / fromMap METHODS
  // ============================================
  // Convert to/from Map for debugging or JSON export

  /// Converts this object to a Map (like JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobName': jobName,
      'companyName': companyName,
      'jobLink': jobLink,
      'contactMethod': contactMethod,
      'cvUsed': cvUsed,
      'notes': notes,
      'followUpDate': followUpDate,
      'source': source,
      'contactEmail': contactEmail,
      'applicationDate': applicationDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Creates a JobApplication from a Map
  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as String,
      jobName: map['jobName'] as String,
      companyName: map['companyName'] as String?,
      jobLink: map['jobLink'] as String?,
      contactMethod: map['contactMethod'] as String?,
      cvUsed: map['cvUsed'] as String?,
      notes: map['notes'] as String?,
      followUpDate: map['followUpDate'] as String?,
      source: map['source'] as String?,
      contactEmail: map['contactEmail'] as String?,
      applicationDate: map['applicationDate'] as String?,
      status: map['status'] as String?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  @override
  String toString() {
    return 'JobApplication(id: $id, jobName: $jobName, company: $companyName, status: $status)';
  }
}
