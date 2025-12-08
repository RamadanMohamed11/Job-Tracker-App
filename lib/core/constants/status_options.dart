/// Job application status options
/// Defines all possible states a job application can be in
enum JobStatus {
  applied,
  underReview,
  interviewScheduled,
  interviewed,
  assessment,
  offerReceived,
  accepted,
  rejected,
  withdrawn,
  onHold,
}

/// Extension to add helper methods to JobStatus enum
extension JobStatusExtension on JobStatus {
  /// Returns a user-friendly display name for the status
  String get displayName {
    switch (this) {
      case JobStatus.applied:
        return 'Applied';
      case JobStatus.underReview:
        return 'Under Review';
      case JobStatus.interviewScheduled:
        return 'Interview Scheduled';
      case JobStatus.interviewed:
        return 'Interviewed';
      case JobStatus.assessment:
        return 'Assessment';
      case JobStatus.offerReceived:
        return 'Offer Received';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.rejected:
        return 'Rejected';
      case JobStatus.withdrawn:
        return 'Withdrawn';
      case JobStatus.onHold:
        return 'On Hold';
    }
  }

  /// Returns the status from a string value
  static JobStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll(' ', '')) {
      case 'applied':
        return JobStatus.applied;
      case 'underreview':
        return JobStatus.underReview;
      case 'interviewscheduled':
        return JobStatus.interviewScheduled;
      case 'interviewed':
        return JobStatus.interviewed;
      case 'assessment':
        return JobStatus.assessment;
      case 'offerreceived':
        return JobStatus.offerReceived;
      case 'accepted':
        return JobStatus.accepted;
      case 'rejected':
        return JobStatus.rejected;
      case 'withdrawn':
        return JobStatus.withdrawn;
      case 'onhold':
        return JobStatus.onHold;
      default:
        return JobStatus.applied;
    }
  }
}

/// Predefined list of job sources
class JobSources {
  JobSources._();

  static const List<String> sources = [
    'LinkedIn',
    'Indeed',
    'WUZZUF',
    'Glassdoor',
    'Bayt.com',
    'Company Website',
    'Referral',
    'Recruiter Outreach',
    'GitHub Jobs',
    'Stack Overflow Jobs',
    'Twitter/X',
    'WhatsApp',
    'Other',
  ];
}

/// Sort options for job list
enum SortOption { dateNewest, dateOldest, nameAZ, nameZA }

/// Extension to add helper methods to SortOption enum
extension SortOptionExtension on SortOption {
  /// Returns a user-friendly display name for the sort option
  String get displayName {
    switch (this) {
      case SortOption.dateNewest:
        return 'Newest First';
      case SortOption.dateOldest:
        return 'Oldest First';
      case SortOption.nameAZ:
        return 'Name (A-Z)';
      case SortOption.nameZA:
        return 'Name (Z-A)';
    }
  }
}
