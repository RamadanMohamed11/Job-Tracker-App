import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/constants.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../data/models/job_application.dart';
import '../../cubits/jobs_cubit.dart';

// ============================================
// ADD/EDIT JOB FORM SCREEN
// ============================================
// A form screen for creating new jobs or editing existing ones.
// Features:
// - Job Name (required)
// - All optional fields with appropriate input types
// - Date pickers for dates
// - Dropdown for status and source
// - Form validation
// - Save/Cancel buttons

class JobFormScreen extends StatefulWidget {
  /// If provided, the form will edit this job. Otherwise, it creates a new job.
  final JobApplication? jobToEdit;

  const JobFormScreen({super.key, this.jobToEdit});

  /// Helper to determine if we're editing or creating
  bool get isEditing => jobToEdit != null;

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each field
  late final TextEditingController _jobNameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _jobLinkController;
  late final TextEditingController _contactMethodController;
  late final TextEditingController _cvUsedController;
  late final TextEditingController _notesController;
  late final TextEditingController _contactEmailController;

  // Selected values for dropdowns and date pickers
  JobStatus? _selectedStatus;
  String? _selectedSource;
  DateTime? _applicationDate;
  DateTime? _followUpDate;

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if editing
    final job = widget.jobToEdit;
    _jobNameController = TextEditingController(text: job?.jobName ?? '');
    _companyNameController = TextEditingController(
      text: job?.companyName ?? '',
    );
    _jobLinkController = TextEditingController(text: job?.jobLink ?? '');
    _contactMethodController = TextEditingController(
      text: job?.contactMethod ?? '',
    );
    _cvUsedController = TextEditingController(text: job?.cvUsed ?? '');
    _notesController = TextEditingController(text: job?.notes ?? '');
    _contactEmailController = TextEditingController(
      text: job?.contactEmail ?? '',
    );

    // Initialize selected values
    _selectedStatus = job?.statusEnum ?? JobStatus.applied;
    _selectedSource = job?.source;
    _applicationDate = _parseDate(job?.applicationDate);
    _followUpDate = _parseDate(job?.followUpDate);
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _jobNameController.dispose();
    _companyNameController.dispose();
    _jobLinkController.dispose();
    _contactMethodController.dispose();
    _cvUsedController.dispose();
    _notesController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editJob : AppStrings.addJob),
        actions: [
          // Save button in app bar
          TextButton(
            onPressed: _isLoading ? null : _saveJob,
            child: Text(
              AppStrings.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ============================================
                    // REQUIRED FIELD: Job Name
                    // ============================================
                    _buildSectionHeader(AppStrings.jobName, isRequired: true),
                    TextFormField(
                      controller: _jobNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Flutter Developer',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Job name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // COMPANY NAME
                    // ============================================
                    _buildSectionHeader(AppStrings.companyName),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Google, Microsoft',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // STATUS DROPDOWN
                    // ============================================
                    _buildSectionHeader(AppStrings.status),
                    DropdownButtonFormField<JobStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(),
                      items: JobStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // APPLICATION DATE
                    // ============================================
                    _buildSectionHeader(AppStrings.applicationDate),
                    _buildDatePicker(
                      value: _applicationDate,
                      hintText: 'Select application date',
                      onChanged: (date) {
                        setState(() => _applicationDate = date);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // SOURCE DROPDOWN
                    // ============================================
                    _buildSectionHeader(AppStrings.source),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSource,
                      decoration: const InputDecoration(
                        hintText: 'Select source',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Select source...'),
                        ),
                        ...JobSources.sources.map((source) {
                          return DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSource = value);
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // JOB LINK
                    // ============================================
                    _buildSectionHeader(AppStrings.jobLink),
                    TextFormField(
                      controller: _jobLinkController,
                      decoration: const InputDecoration(
                        hintText: 'https://...',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // CONTACT EMAIL
                    // ============================================
                    _buildSectionHeader(AppStrings.contactEmail),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        hintText: 'recruiter@company.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Simple email validation
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // CONTACT METHOD
                    // ============================================
                    _buildSectionHeader(AppStrings.contactMethod),
                    TextFormField(
                      controller: _contactMethodController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Email, LinkedIn, Phone',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // CV/RESUME USED
                    // ============================================
                    _buildSectionHeader(AppStrings.cvUsed),
                    TextFormField(
                      controller: _cvUsedController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Flutter_CV_2024.pdf',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // FOLLOW-UP DATE
                    // ============================================
                    _buildSectionHeader(AppStrings.followUpDate),
                    _buildDatePicker(
                      value: _followUpDate,
                      hintText: 'Select follow-up date',
                      onChanged: (date) {
                        setState(() => _followUpDate = date);
                      },
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // NOTES
                    // ============================================
                    _buildSectionHeader(AppStrings.notes),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Any additional notes...',
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 32),

                    // ============================================
                    // SAVE BUTTON
                    // ============================================
                    ElevatedButton(
                      onPressed: _saveJob,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.isEditing ? 'Update Job' : 'Add Job',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel button
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        AppStrings.cancel,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================
  // HELPER: Section Header
  // ============================================
  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // HELPER: Date Picker Field
  // ============================================
  Widget _buildDatePicker({
    required DateTime? value,
    required String hintText,
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hintText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onChanged(null),
                ),
              const Icon(Icons.calendar_today),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: value != null
            ? Text(DateFormat('MMM d, yyyy').format(value))
            : Text(
                hintText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
      ),
    );
  }

  // ============================================
  // SAVE JOB
  // ============================================
  Future<void> _saveJob() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<JobsCubit>();

    // Check for duplicates before saving
    final duplicates = cubit.findDuplicates(
      jobName: _jobNameController.text.trim(),
      companyName: _companyNameController.text.trim().isEmpty
          ? null
          : _companyNameController.text.trim(),
      excludeJobId: widget.isEditing ? widget.jobToEdit!.id : null,
    );

    // If duplicates found, show warning dialog
    if (duplicates.isNotEmpty) {
      final shouldProceed = await _showDuplicateWarning(duplicates);
      if (shouldProceed != true) {
        return; // User cancelled
      }
    }

    setState(() => _isLoading = true);

    try {
      // Get notification time from settings
      if (!mounted) return;
      final themeState = context.read<ThemeCubit>().state;

      if (widget.isEditing) {
        // Update existing job
        await cubit.updateJob(
          id: widget.jobToEdit!.id,
          jobName: _jobNameController.text.trim(),
          companyName: _companyNameController.text.trim().isEmpty
              ? null
              : _companyNameController.text.trim(),
          jobLink: _jobLinkController.text.trim().isEmpty
              ? null
              : _jobLinkController.text.trim(),
          contactMethod: _contactMethodController.text.trim().isEmpty
              ? null
              : _contactMethodController.text.trim(),
          cvUsed: _cvUsedController.text.trim().isEmpty
              ? null
              : _cvUsedController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          contactEmail: _contactEmailController.text.trim().isEmpty
              ? null
              : _contactEmailController.text.trim(),
          status: _selectedStatus,
          source: _selectedSource,
          applicationDate: _applicationDate?.toIso8601String(),
          followUpDate: _followUpDate?.toIso8601String(),
          notificationHour: themeState.notificationHour,
          notificationMinute: themeState.notificationMinute,
        );
      } else {
        // Create new job
        await cubit.addJob(
          jobName: _jobNameController.text.trim(),
          companyName: _companyNameController.text.trim().isEmpty
              ? null
              : _companyNameController.text.trim(),
          jobLink: _jobLinkController.text.trim().isEmpty
              ? null
              : _jobLinkController.text.trim(),
          contactMethod: _contactMethodController.text.trim().isEmpty
              ? null
              : _contactMethodController.text.trim(),
          cvUsed: _cvUsedController.text.trim().isEmpty
              ? null
              : _cvUsedController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          contactEmail: _contactEmailController.text.trim().isEmpty
              ? null
              : _contactEmailController.text.trim(),
          status: _selectedStatus,
          source: _selectedSource,
          applicationDate: _applicationDate?.toIso8601String(),
          followUpDate: _followUpDate?.toIso8601String(),
          notificationHour: themeState.notificationHour,
          notificationMinute: themeState.notificationMinute,
        );
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? AppStrings.jobUpdated : AppStrings.jobAdded,
            ),
          ),
        );
        // Go back to home screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ============================================
  // DUPLICATE WARNING DIALOG
  // ============================================
  Future<bool?> _showDuplicateWarning(List<JobApplication> duplicates) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.orange,
        ),
        title: const Text('Potential Duplicate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A similar job application already exists:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...duplicates
                .take(3)
                .map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.jobName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (job.companyName != null &&
                              job.companyName!.isNotEmpty)
                            Text(
                              job.companyName!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            if (duplicates.length > 3)
              Text(
                '...and ${duplicates.length - 3} more',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            const Text('Do you still want to save this job?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
  }
}
