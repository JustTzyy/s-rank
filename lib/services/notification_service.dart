import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'preferences_service.dart';

class NotificationService {
  static NotificationService? _instance;
  
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PreferencesService _preferencesService = PreferencesService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  // Schedule study reminders based on user preferences
  Future<void> scheduleStudyReminders() async {
    await initialize();
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Cancel existing study reminders
      await cancelStudyReminders();

      final preferences = await _preferencesService.getStudyPreferences();
      if (preferences == null || !preferences.studyRemindersEnabled) return;

      final notificationSettings = await _preferencesService.getNotificationSettings();
      if (notificationSettings == null || !notificationSettings.notificationsEnabled) return;

      // Schedule reminders for each selected day
      for (final day in preferences.selectedReminderDays) {
        await _scheduleWeeklyReminder(
          day: day,
          hour: preferences.reminderHour,
          minute: preferences.reminderMinute,
        );
      }
    } catch (e) {
      print('Error scheduling study reminders: $e');
    }
  }

  Future<void> _scheduleWeeklyReminder({
    required String day,
    required int hour,
    required int minute,
  }) async {
    final dayIndex = _getDayIndex(day);
    if (dayIndex == -1) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_reminders',
      'Study Reminders',
      channelDescription: 'Reminders to study flashcards',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      dayIndex, // Use day index as notification ID
      'Time to Study! 📚',
      'Your scheduled study session is ready. Let\'s continue your learning journey!',
      _nextInstanceOfDay(dayIndex, hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'study_reminder',
    );
  }

  int _getDayIndex(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return -1;
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }

  // Cancel all study reminders
  Future<void> cancelStudyReminders() async {
    await initialize();
    
    // Cancel all study reminder notifications (IDs 1-7 for days of week)
    for (int i = 1; i <= 7; i++) {
      await _notifications.cancel(i);
    }
  }

  // Schedule goal reminder
  Future<void> scheduleGoalReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'goal_reminders',
      'Goal Reminders',
      channelDescription: 'Reminders about study goals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'goal_reminder',
    );
  }

  // Schedule streak reminder
  Future<void> scheduleStreakReminder() async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'streak_reminders',
      'Streak Reminders',
      channelDescription: 'Reminders to maintain study streaks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for tomorrow at 9 AM
    final tomorrow = tz.TZDateTime.now(tz.local).add(const Duration(days: 1));
    final scheduledTime = tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Don\'t Break Your Streak! 🔥',
      'You\'re on a roll! Keep your study streak alive by studying today.',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'streak_reminder',
    );
  }

  // Schedule break reminder
  Future<void> scheduleBreakReminder({
    required int minutesFromNow,
  }) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'break_reminders',
      'Break Reminders',
      channelDescription: 'Reminders to take study breaks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutesFromNow));

    await _notifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Time for a Break! ☕',
      'You\'ve been studying for a while. Take a short break to refresh your mind.',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'break_reminder',
    );
  }

  // Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'achievements',
      'Achievements',
      channelDescription: 'Achievement and milestone notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: 'achievement',
    );
  }

  // Show progress update notification
  Future<void> showProgressNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'progress_updates',
      'Progress Updates',
      channelDescription: 'Progress and goal achievement notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: 'progress_update',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await initialize();
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    return await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    await initialize();
    
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return true; // iOS permissions are handled in initialization
  }
}
