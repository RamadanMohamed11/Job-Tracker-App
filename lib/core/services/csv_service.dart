import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/job_repository.dart';
import '../../core/constants/status_options.dart';

// ============================================
// CSV SERVICE
// ============================================
// Handles importing and exporting job data as CSV files.
// Export: Converts all jobs to CSV and shares the file.
// Import: Reads CSV file and creates jobs from it.

class CsvService {
  final JobRepository _repository;

  CsvService({JobRepository? repository})
    : _repository = repository ?? JobRepository();

  // CSV column headers
  static const List<String> _headers = [
    'Job Name',
    'Company',
    'Status',
    'Application Date',
    'Follow-up Date',
    'Job Link',
    'Source',
    'Contact Method',
    'Contact Email',
    'CV Used',
    'Notes',
    'Is Pinned',
  ];

  // ============================================
  // EXPORT TO CSV
  // ============================================
  /// Exports all jobs to a CSV file and shares it.
  /// Returns the number of jobs exported, or -1 on error.
  Future<int> exportJobs() async {
    try {
      final jobs = _repository.getAllJobs();

      if (jobs.isEmpty) {
        debugPrint('No jobs to export');
        return 0;
      }

      // Convert jobs to CSV rows
      final List<List<dynamic>> rows = [_headers];

      for (final job in jobs) {
        rows.add([
          job.jobName,
          job.companyName ?? '',
          job.status ?? 'Applied',
          job.applicationDate ?? '',
          job.followUpDate ?? '',
          job.jobLink ?? '',
          job.source ?? '',
          job.contactMethod ?? '',
          job.contactEmail ?? '',
          job.cvUsed ?? '',
          job.notes ?? '',
          job.isPinned ? 'Yes' : 'No',
        ]);
      }

      // Generate CSV string
      const converter = ListToCsvConverter();
      final csvString = converter.convert(rows);

      // Save to temp file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final filePath = '${directory.path}/job_tracker_export_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      debugPrint('CSV exported to: $filePath');

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Job Tracker Export',
        text: 'Exported ${jobs.length} job applications',
      );

      return jobs.length;
    } catch (e, stack) {
      debugPrint('Error exporting CSV: $e');
      debugPrint('Stack: $stack');
      return -1;
    }
  }

  // ============================================
  // IMPORT FROM CSV
  // ============================================
  /// Opens file picker and imports jobs from selected CSV file.
  /// Returns the number of jobs imported, or -1 on error.
  Future<int> importJobs() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return 0;
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();

      // Parse CSV
      const converter = CsvToListConverter();
      final List<List<dynamic>> rows = converter.convert(csvString);

      if (rows.isEmpty) {
        debugPrint('CSV file is empty');
        return 0;
      }

      // Skip header row
      final dataRows = rows.length > 1 ? rows.sublist(1) : [];

      int importedCount = 0;

      for (final row in dataRows) {
        if (row.isEmpty || row[0].toString().trim().isEmpty) {
          continue; // Skip empty rows
        }

        try {
          final jobName = row[0].toString().trim();
          final companyName = _getValueAtIndex(row, 1);
          final statusString = _getValueAtIndex(row, 2);
          final applicationDate = _getValueAtIndex(row, 3);
          final followUpDate = _getValueAtIndex(row, 4);
          final jobLink = _getValueAtIndex(row, 5);
          final source = _getValueAtIndex(row, 6);
          final contactMethod = _getValueAtIndex(row, 7);
          final contactEmail = _getValueAtIndex(row, 8);
          final cvUsed = _getValueAtIndex(row, 9);
          final notes = _getValueAtIndex(row, 10);
          // isPinned is handled separately since it needs boolean conversion

          // Parse status
          JobStatus? status;
          if (statusString != null && statusString.isNotEmpty) {
            status = JobStatusExtension.fromString(statusString);
          }

          // Add job
          await _repository.addJob(
            jobName: jobName,
            companyName: companyName,
            status: status,
            applicationDate: applicationDate,
            followUpDate: followUpDate,
            jobLink: jobLink,
            source: source,
            contactMethod: contactMethod,
            contactEmail: contactEmail,
            cvUsed: cvUsed,
            notes: notes,
          );

          importedCount++;
          debugPrint('Imported: $jobName');
        } catch (e) {
          debugPrint('Error importing row: $e');
          // Continue with next row
        }
      }

      debugPrint('Successfully imported $importedCount jobs');
      return importedCount;
    } catch (e, stack) {
      debugPrint('Error importing CSV: $e');
      debugPrint('Stack: $stack');
      return -1;
    }
  }

  /// Helper to safely get value at index
  String? _getValueAtIndex(List<dynamic> row, int index) {
    if (index >= row.length) return null;
    final value = row[index].toString().trim();
    return value.isEmpty ? null : value;
  }

  // ============================================
  // GENERATE SAMPLE CSV
  // ============================================
  /// Returns a sample CSV string for users to download as a template.
  String getSampleCsv() {
    final rows = [
      _headers,
      [
        'Flutter Developer',
        'Google',
        'Applied',
        '2024-12-01',
        '2024-12-15',
        'https://careers.google.com/job123',
        'LinkedIn',
        'Email',
        'recruiter@google.com',
        'Flutter_CV.pdf',
        'Great opportunity!',
        'No',
      ],
      [
        'Senior Engineer',
        'Microsoft',
        'Interview Scheduled',
        '2024-11-28',
        '2024-12-10',
        '',
        'Indeed',
        '',
        '',
        'General_CV.pdf',
        '',
        'Yes',
      ],
    ];

    const converter = ListToCsvConverter();
    return converter.convert(rows);
  }
}
