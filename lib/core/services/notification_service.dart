import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Use the app icon
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
  // REQUEST PERMISSIONS
  // ============================================
  Future<void> _requestAndroidPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
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
    // Generate a unique notification ID from the job ID
    final notificationId = jobId.hashCode.abs() % 2147483647;

    // Create the notification content
    final title = 'Follow-up Reminder 📋';
    final body = companyName != null && companyName.isNotEmpty
        ? 'Time to follow up on your "$jobName" application at $companyName'
        : 'Time to follow up on your "$jobName" application';

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'follow_up_reminders', // Channel ID
      'Follow-up Reminders', // Channel name
      channelDescription: 'Reminders for job application follow-ups',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    // Only schedule if the date is in the future
    if (scheduledDate.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jobId, // Store job ID to open details on tap
      );

      debugPrint('Scheduled notification for job $jobId on $scheduledDate');
    } else {
      debugPrint(
        'Follow-up date $scheduledDate is in the past, not scheduling notification',
      );
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
