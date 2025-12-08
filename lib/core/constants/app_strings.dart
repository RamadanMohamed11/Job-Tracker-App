/// App string constants for consistent text usage
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Job Tracker';
  static const String appVersion = '1.0.0';

  // Navigation
  static const String home = 'Home';
  static const String settings = 'Settings';
  static const String addJob = 'Add Job';
  static const String editJob = 'Edit Job';
  static const String jobDetails = 'Job Details';

  // Form Labels
  static const String jobName = 'Job Name';
  static const String jobNameHint = 'Enter position/job title';
  static const String jobNameRequired = 'Job name is required';

  static const String companyName = 'Company Name';
  static const String companyNameHint = 'Enter company name';

  static const String jobLink = 'Job Link';
  static const String jobLinkHint = 'https://...';

  static const String contactMethod = 'Contact Method';
  static const String contactMethodHint = 'Email, phone, LinkedIn, etc.';

  static const String cvUsed = 'CV/Resume Used';
  static const String cvUsedHint = 'Which resume did you apply with?';

  static const String notes = 'Notes';
  static const String notesHint = 'Add any additional notes...';

  static const String followUpDate = 'Follow-up Date';
  static const String source = 'Source';
  static const String sourceHint = 'Where did you find this job?';

  static const String contactEmail = 'Contact Email';
  static const String contactEmailHint = 'recruiter@company.com';

  static const String applicationDate = 'Application Date';
  static const String status = 'Status';

  // Buttons
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String clear = 'Clear';
  static const String viewJob = 'View Job';
  static const String confirm = 'Confirm';

  // Messages
  static const String noJobsFound = 'No jobs found';
  static const String noJobsYet =
      'No job applications yet.\nTap + to add your first job!';
  static const String jobSaved = 'Job saved successfully';
  static const String jobDeleted = 'Job deleted';
  static const String jobUpdated = 'Job updated successfully';

  // Dialogs
  static const String deleteConfirmTitle = 'Delete Job';
  static const String deleteConfirmMessage =
      'Are you sure you want to delete this job application? This action cannot be undone.';

  // Filters & Sort
  static const String search = 'Search';
  static const String searchHint = 'Search jobs...';
  static const String filterByStatus = 'Filter by Status';
  static const String allStatuses = 'All Statuses';
  static const String sortBy = 'Sort By';

  // Settings
  static const String theme = 'Theme';
  static const String lightMode = 'Light';
  static const String darkMode = 'Dark';
  static const String systemMode = 'System';
  static const String appearance = 'Appearance';

  // Form Sections
  static const String basicInfo = 'Basic Information';
  static const String applicationDetails = 'Application Details';
  static const String contactInfo = 'Contact Information';
  static const String resumeAndSource = 'Resume & Source';
  static const String followUp = 'Follow-up';
  static const String additionalNotes = 'Additional Notes';

  // Misc
  static const String required = '(required)';
  static const String optional = '(optional)';
  static const String showingJobs = 'Showing';
  static const String jobs = 'jobs';
  static const String job = 'job';
}
