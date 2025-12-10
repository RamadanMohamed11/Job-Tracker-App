import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ============================================
// NOTIFICATION SERVICE
// ============================================
// Manages local notifications for follow-up reminders.
// Features:
// - Initialize notification channels
// - Schedule notifications for follow-up dates
// - Cancel notifications when job is updated/deleted
// - Handle notification taps to open job details

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // The main notification plugin instance
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Callback for when user taps a notification
  static Function(String? jobId)? onNotificationTap;

  // ============================================
  // INITIALIZATION
  // ============================================
  /// Initialize the notification service. Call this in main.dart before runApp.
  Future<void> initialize() async {
    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Set the local timezone based on device timezone
    await _configureLocalTimezone();

    // Android settings - use launcher_icon to match AndroidManifest.xml
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    debugPrint('NotificationService initialized');
  }

  // ============================================
  // CONFIGURE LOCAL TIMEZONE
  // ============================================
  Future<void> _configureLocalTimezone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      debugPrint('Failed to get timezone, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  // ============================================
  // REQUEST PERMISSIONS
  // ============================================
  Future<void> _requestAndroidPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Request notification permission (Android 13+)
        final notificationGranted = await androidPlugin
            .requestNotificationsPermission();
        debugPrint('Notification permission granted: $notificationGranted');

        // Request exact alarm permission (Android 12+)
        final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
        debugPrint('Exact alarm permission granted: $alarmGranted');
      }
    } catch (e) {
      debugPrint('Error requesting Android permissions: $e');
    }
  }

  // ============================================
  // SCHEDULE NOTIFICATION
  // ============================================
  /// Schedules a notification for a job's follow-up date.
  ///
  /// [jobId] - Unique ID of the job (used to cancel later)
  /// [jobName] - Name of the job position
  /// [companyName] - Company name (optional)
  /// [followUpDate] - The date/time to show the notification
  /// [hour] - Hour to show notification (0-23), defaults to 9
  /// [minute] - Minute to show notification (0-59), defaults to 0
  Future<void> scheduleFollowUpNotification({
    required String jobId,
    required String jobName,
    String? companyName,
    required DateTime followUpDate,
    int hour = 9,
    int minute = 0,
  }) async {
    debugPrint('scheduleFollowUpNotification called for job: $jobName');
    debugPrint('  followUpDate: $followUpDate, hour: $hour, minute: $minute');

    try {
      // Generate a unique notification ID from the job ID
      final notificationId = jobId.hashCode.abs() % 2147483647;

      // Create the notification content
      final title = 'Follow-up Reminder 📋';
      final body = companyName != null && companyName.isNotEmpty
          ? 'Time to follow up on your "$jobName" application at $companyName'
          : 'Time to follow up on your "$jobName" application';

      // Android notification details
      // Use launcher_icon which matches the app icon defined in AndroidManifest.xml
      const androidDetails = AndroidNotificationDetails(
        'follow_up_reminders', // Channel ID
        'Follow-up Reminders', // Channel name
        channelDescription: 'Reminders for job application follow-ups',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon', // Must match AndroidManifest.xml icon
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification at the specified time on the follow-up date
      final scheduledDate = DateTime(
        followUpDate.year,
        followUpDate.month,
        followUpDate.day,
        hour,
        minute,
      );

      debugPrint('  Calculated scheduled date: $scheduledDate');
      debugPrint('  Current time: ${DateTime.now()}');
      debugPrint('  Is in future: ${scheduledDate.isAfter(DateTime.now())}');

      // Only schedule if the date is in the future
      if (scheduledDate.isAfter(DateTime.now())) {
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        debugPrint('  TZ scheduled date: $tzScheduledDate');

        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jobId, // Store job ID to open details on tap
        );

        debugPrint(
          '✅ Scheduled notification ID $notificationId for job $jobId on $scheduledDate',
        );
      } else {
        debugPrint(
          '⚠️ Follow-up date $scheduledDate is in the past, not scheduling notification',
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Error scheduling notification: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  // ============================================
  // SCHEDULE INTERVIEW PREP NOTIFICATION
  // ============================================
  /// Schedules an interview prep reminder notification.
  /// Uses jobId_interview as the unique notification ID.
  Future<void> scheduleInterviewPrepNotification({
    required String jobId,
    required String jobName,
    String? companyName,
    required DateTime interviewDate,
    required DateTime reminderDate,
    int hour = 9,
    int minute = 0,
  }) async {
    debugPrint('scheduleInterviewPrepNotification called:');
    debugPrint('  jobId: $jobId');
    debugPrint('  jobName: $jobName');
    debugPrint('  companyName: $companyName');
    debugPrint('  interviewDate: $interviewDate');
    debugPrint('  reminderDate: $reminderDate');
    debugPrint('  hour: $hour, minute: $minute');

    try {
      // Generate unique notification ID from job ID with "_interview" suffix
      final notificationId = '${jobId}_interview'.hashCode.abs() % 2147483647;
      debugPrint('  Generated notification ID: $notificationId');

      // Create the notification content
      final title = 'Interview Prep Reminder 🎯';
      final formattedDate =
          '${interviewDate.day}/${interviewDate.month}/${interviewDate.year}';
      final body = companyName != null && companyName.isNotEmpty
          ? 'Your interview for "$jobName" at $companyName is tomorrow ($formattedDate)! Time to prepare!'
          : 'Your interview for "$jobName" is tomorrow ($formattedDate)! Time to prepare!';

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'interview_prep_reminders', // Channel ID
        'Interview Prep Reminders', // Channel name
        channelDescription: 'Reminders to prepare for upcoming interviews',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification at the specified time on the reminder date
      final scheduledDate = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );

      debugPrint('  Calculated scheduled date: $scheduledDate');
      debugPrint('  Current time: ${DateTime.now()}');
      debugPrint('  Is in future: ${scheduledDate.isAfter(DateTime.now())}');

      // Only schedule if the date is in the future
      if (scheduledDate.isAfter(DateTime.now())) {
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
        debugPrint('  TZ scheduled date: $tzScheduledDate');

        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jobId, // Store job ID to open details on tap
        );

        debugPrint(
          '✅ Scheduled interview prep notification ID $notificationId for job $jobId on $scheduledDate',
        );
      } else {
        debugPrint(
          '⚠️ Reminder date $scheduledDate is in the past, not scheduling notification',
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Error scheduling interview prep notification: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  // ============================================
  // TEST SCHEDULED NOTIFICATION (for debugging)
  // ============================================
  /// Schedules a test notification for 10 seconds from now.
  Future<void> testScheduledNotification() async {
    debugPrint(
      'testScheduledNotification: Scheduling notification in 10 seconds...',
    );

    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
    debugPrint('  Scheduled for: $scheduledTime');

    const androidDetails = AndroidNotificationDetails(
      'follow_up_reminders',
      'Follow-up Reminders',
      channelDescription: 'Reminders for job application follow-ups',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      debugPrint('  TZ scheduled time: $tzScheduledTime');

      await _notifications.zonedSchedule(
        999999, // Test notification ID
        'Scheduled Test ⏰',
        'This notification was scheduled 10 seconds ago!',
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Test notification scheduled successfully!');
    } catch (e, stack) {
      debugPrint('❌ Error scheduling test notification: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  // ============================================
  // CANCEL NOTIFICATION
  // ============================================
  /// Cancels a scheduled notification for a job.
  Future<void> cancelNotification(String jobId) async {
    final notificationId = jobId.hashCode.abs() % 2147483647;
    await _notifications.cancel(notificationId);
    debugPrint('Cancelled notification for job $jobId');
  }

  // ============================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================
  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  // ============================================
  // NOTIFICATION RESPONSE HANDLER
  // ============================================
  /// Called when user taps on a notification.
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notification tapped with payload: $payload');

    // Call the callback with the job ID
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  // ============================================
  // SHOW IMMEDIATE NOTIFICATION (for testing)
  // ============================================
  /// Shows a notification immediately (useful for testing).
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'follow_up_reminders',
      'Follow-up Reminders',
      channelDescription: 'Reminders for job application follow-ups',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Test Notification',
      'This is a test notification from Job Tracker',
      notificationDetails,
    );
  }

  // ============================================
  // CHECK PENDING NOTIFICATIONS
  // ============================================
  /// Returns a list of pending notifications (for debugging).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
