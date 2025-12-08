import 'package:flutter/material.dart';
import 'status_options.dart';

/// App color constants for consistent theming
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF3B82F6);

  // Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFF3F4F6);
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Colors.white;

  // Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Border Colors
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF4B5563);

  // Status Colors - Light Mode Backgrounds
  static const Color statusBlueLight = Color(0xFFDBEAFE);
  static const Color statusYellowLight = Color(0xFFFEF3C7);
  static const Color statusGreenLight = Color(0xFFD1FAE5);
  static const Color statusRedLight = Color(0xFFFEE2E2);
  static const Color statusGrayLight = Color(0xFFF3F4F6);

  // Status Colors - Light Mode Text
  static const Color statusBlueTextLight = Color(0xFF1E40AF);
  static const Color statusYellowTextLight = Color(0xFF92400E);
  static const Color statusGreenTextLight = Color(0xFF065F46);
  static const Color statusRedTextLight = Color(0xFF991B1B);
  static const Color statusGrayTextLight = Color(0xFF1F2937);

  // Status Colors - Dark Mode Backgrounds
  static const Color statusBlueDark = Color(0xFF1E3A5F);
  static const Color statusYellowDark = Color(0xFF78350F);
  static const Color statusGreenDark = Color(0xFF064E3B);
  static const Color statusRedDark = Color(0xFF7F1D1D);
  static const Color statusGrayDark = Color(0xFF374151);

  // Status Colors - Dark Mode Text
  static const Color statusBlueTextDark = Color(0xFFBFDBFE);
  static const Color statusYellowTextDark = Color(0xFFFDE68A);
  static const Color statusGreenTextDark = Color(0xFFA7F3D0);
  static const Color statusRedTextDark = Color(0xFFFECACA);
  static const Color statusGrayTextDark = Color(0xFFE5E7EB);

  /// Returns the background color for a given job status
  static Color getStatusBackgroundColor(JobStatus status, bool isDark) {
    if (isDark) {
      switch (status) {
        case JobStatus.applied:
        case JobStatus.underReview:
          return statusBlueDark;
        case JobStatus.interviewScheduled:
        case JobStatus.interviewed:
        case JobStatus.assessment:
          return statusYellowDark;
        case JobStatus.offerReceived:
        case JobStatus.accepted:
          return statusGreenDark;
        case JobStatus.rejected:
        case JobStatus.withdrawn:
          return statusRedDark;
        case JobStatus.onHold:
          return statusGrayDark;
      }
    } else {
      switch (status) {
        case JobStatus.applied:
        case JobStatus.underReview:
          return statusBlueLight;
        case JobStatus.interviewScheduled:
        case JobStatus.interviewed:
        case JobStatus.assessment:
          return statusYellowLight;
        case JobStatus.offerReceived:
        case JobStatus.accepted:
          return statusGreenLight;
        case JobStatus.rejected:
        case JobStatus.withdrawn:
          return statusRedLight;
        case JobStatus.onHold:
          return statusGrayLight;
      }
    }
  }

  /// Returns the text color for a given job status
  static Color getStatusTextColor(JobStatus status, bool isDark) {
    if (isDark) {
      switch (status) {
        case JobStatus.applied:
        case JobStatus.underReview:
          return statusBlueTextDark;
        case JobStatus.interviewScheduled:
        case JobStatus.interviewed:
        case JobStatus.assessment:
          return statusYellowTextDark;
        case JobStatus.offerReceived:
        case JobStatus.accepted:
          return statusGreenTextDark;
        case JobStatus.rejected:
        case JobStatus.withdrawn:
          return statusRedTextDark;
        case JobStatus.onHold:
          return statusGrayTextDark;
      }
    } else {
      switch (status) {
        case JobStatus.applied:
        case JobStatus.underReview:
          return statusBlueTextLight;
        case JobStatus.interviewScheduled:
        case JobStatus.interviewed:
        case JobStatus.assessment:
          return statusYellowTextLight;
        case JobStatus.offerReceived:
        case JobStatus.accepted:
          return statusGreenTextLight;
        case JobStatus.rejected:
        case JobStatus.withdrawn:
          return statusRedTextLight;
        case JobStatus.onHold:
          return statusGrayTextLight;
      }
    }
  }
}
