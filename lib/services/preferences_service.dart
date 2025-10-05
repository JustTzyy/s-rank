import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferencesService {
  static PreferencesService? _instance;
  
  factory PreferencesService() {
    _instance ??= PreferencesService._internal();
    return _instance!;
  }
  
  PreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Study Preferences
  Future<StudyPreferences?> getStudyPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('study')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return StudyPreferences.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error loading study preferences: $e');
      return null;
    }
  }

  Future<void> saveStudyPreferences(StudyPreferences preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('study')
          .set(preferences.toMap());
    } catch (e) {
      print('Error saving study preferences: $e');
      throw Exception('Failed to save study preferences: $e');
    }
  }

  // Progress Settings
  Future<ProgressSettings?> getProgressSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('progress')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return ProgressSettings.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error loading progress settings: $e');
      return null;
    }
  }

  Future<void> saveProgressSettings(ProgressSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('progress')
          .set(settings.toMap());
    } catch (e) {
      print('Error saving progress settings: $e');
      throw Exception('Failed to save progress settings: $e');
    }
  }

  // Notification Settings
  Future<NotificationSettings?> getNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return NotificationSettings.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error loading notification settings: $e');
      return null;
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('notifications')
          .set(settings.toMap());
    } catch (e) {
      print('Error saving notification settings: $e');
      throw Exception('Failed to save notification settings: $e');
    }
  }
}

class StudyPreferences {
  final bool studyRemindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  final List<String> selectedReminderDays;
  final String defaultDifficulty;
  final bool adaptiveDifficulty;
  final bool showHints;
  final int maxHintsPerCard;
  final int sessionDuration;
  final int breakDuration;
  final bool autoAdvance;
  final bool shuffleCards;
  final bool repeatIncorrect;

  StudyPreferences({
    this.studyRemindersEnabled = true,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.selectedReminderDays = const ['Monday', 'Wednesday', 'Friday'],
    this.defaultDifficulty = 'Medium',
    this.adaptiveDifficulty = true,
    this.showHints = true,
    this.maxHintsPerCard = 3,
    this.sessionDuration = 25,
    this.breakDuration = 5,
    this.autoAdvance = true,
    this.shuffleCards = true,
    this.repeatIncorrect = true,
  });

  factory StudyPreferences.fromMap(Map<String, dynamic> data) {
    return StudyPreferences(
      studyRemindersEnabled: data['studyRemindersEnabled'] ?? true,
      reminderHour: data['studyReminderTime']?['hour'] ?? 19,
      reminderMinute: data['studyReminderTime']?['minute'] ?? 0,
      selectedReminderDays: List<String>.from(data['selectedReminderDays'] ?? ['Monday', 'Wednesday', 'Friday']),
      defaultDifficulty: data['defaultDifficulty'] ?? 'Medium',
      adaptiveDifficulty: data['adaptiveDifficulty'] ?? true,
      showHints: data['showHints'] ?? true,
      maxHintsPerCard: data['maxHintsPerCard'] ?? 3,
      sessionDuration: data['sessionDuration'] ?? 25,
      breakDuration: data['breakDuration'] ?? 5,
      autoAdvance: data['autoAdvance'] ?? true,
      shuffleCards: data['shuffleCards'] ?? true,
      repeatIncorrect: data['repeatIncorrect'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studyRemindersEnabled': studyRemindersEnabled,
      'studyReminderTime': {
        'hour': reminderHour,
        'minute': reminderMinute,
      },
      'selectedReminderDays': selectedReminderDays,
      'defaultDifficulty': defaultDifficulty,
      'adaptiveDifficulty': adaptiveDifficulty,
      'showHints': showHints,
      'maxHintsPerCard': maxHintsPerCard,
      'sessionDuration': sessionDuration,
      'breakDuration': breakDuration,
      'autoAdvance': autoAdvance,
      'shuffleCards': shuffleCards,
      'repeatIncorrect': repeatIncorrect,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ProgressSettings {
  final bool trackStudyTime;
  final bool trackAccuracy;
  final bool trackStreaks;
  final bool trackPoints;
  final bool showProgressCharts;
  final bool showDailyGoals;
  final int dailyStudyGoal;
  final int weeklyStudyGoal;
  final int dailyCardGoal;
  final int weeklyCardGoal;
  final bool enableGoalReminders;
  final bool showProgressInHome;
  final bool showProgressInCourses;
  final bool showProgressInDecks;
  final String progressDisplayMode;
  final int dataRetentionDays;
  final bool autoArchiveOldData;
  final bool exportProgressData;

  ProgressSettings({
    this.trackStudyTime = true,
    this.trackAccuracy = true,
    this.trackStreaks = true,
    this.trackPoints = true,
    this.showProgressCharts = true,
    this.showDailyGoals = true,
    this.dailyStudyGoal = 30,
    this.weeklyStudyGoal = 180,
    this.dailyCardGoal = 20,
    this.weeklyCardGoal = 100,
    this.enableGoalReminders = true,
    this.showProgressInHome = true,
    this.showProgressInCourses = true,
    this.showProgressInDecks = true,
    this.progressDisplayMode = 'Detailed',
    this.dataRetentionDays = 365,
    this.autoArchiveOldData = true,
    this.exportProgressData = true,
  });

  factory ProgressSettings.fromMap(Map<String, dynamic> data) {
    return ProgressSettings(
      trackStudyTime: data['trackStudyTime'] ?? true,
      trackAccuracy: data['trackAccuracy'] ?? true,
      trackStreaks: data['trackStreaks'] ?? true,
      trackPoints: data['trackPoints'] ?? true,
      showProgressCharts: data['showProgressCharts'] ?? true,
      showDailyGoals: data['showDailyGoals'] ?? true,
      dailyStudyGoal: data['dailyStudyGoal'] ?? 30,
      weeklyStudyGoal: data['weeklyStudyGoal'] ?? 180,
      dailyCardGoal: data['dailyCardGoal'] ?? 20,
      weeklyCardGoal: data['weeklyCardGoal'] ?? 100,
      enableGoalReminders: data['enableGoalReminders'] ?? true,
      showProgressInHome: data['showProgressInHome'] ?? true,
      showProgressInCourses: data['showProgressInCourses'] ?? true,
      showProgressInDecks: data['showProgressInDecks'] ?? true,
      progressDisplayMode: data['progressDisplayMode'] ?? 'Detailed',
      dataRetentionDays: data['dataRetentionDays'] ?? 365,
      autoArchiveOldData: data['autoArchiveOldData'] ?? true,
      exportProgressData: data['exportProgressData'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackStudyTime': trackStudyTime,
      'trackAccuracy': trackAccuracy,
      'trackStreaks': trackStreaks,
      'trackPoints': trackPoints,
      'showProgressCharts': showProgressCharts,
      'showDailyGoals': showDailyGoals,
      'dailyStudyGoal': dailyStudyGoal,
      'weeklyStudyGoal': weeklyStudyGoal,
      'dailyCardGoal': dailyCardGoal,
      'weeklyCardGoal': weeklyCardGoal,
      'enableGoalReminders': enableGoalReminders,
      'showProgressInHome': showProgressInHome,
      'showProgressInCourses': showProgressInCourses,
      'showProgressInDecks': showProgressInDecks,
      'progressDisplayMode': progressDisplayMode,
      'dataRetentionDays': dataRetentionDays,
      'autoArchiveOldData': autoArchiveOldData,
      'exportProgressData': exportProgressData,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class NotificationSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool ledEnabled;
  final bool studyReminders;
  final bool goalReminders;
  final bool streakReminders;
  final bool breakReminders;
  final bool achievementNotifications;
  final bool levelUpNotifications;
  final bool milestoneNotifications;
  final bool badgeNotifications;
  final bool progressUpdates;
  final bool weeklyReports;
  final bool monthlyReports;
  final bool goalAchievements;
  final bool friendRequests;
  final bool friendActivity;
  final bool leaderboardUpdates;
  final bool challengeInvites;
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;

  NotificationSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.ledEnabled = true,
    this.studyReminders = true,
    this.goalReminders = true,
    this.streakReminders = true,
    this.breakReminders = true,
    this.achievementNotifications = true,
    this.levelUpNotifications = true,
    this.milestoneNotifications = true,
    this.badgeNotifications = true,
    this.progressUpdates = true,
    this.weeklyReports = true,
    this.monthlyReports = false,
    this.goalAchievements = true,
    this.friendRequests = true,
    this.friendActivity = false,
    this.leaderboardUpdates = true,
    this.challengeInvites = true,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 8,
    this.quietHoursEndMinute = 0,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> data) {
    return NotificationSettings(
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      ledEnabled: data['ledEnabled'] ?? true,
      studyReminders: data['studyReminders'] ?? true,
      goalReminders: data['goalReminders'] ?? true,
      streakReminders: data['streakReminders'] ?? true,
      breakReminders: data['breakReminders'] ?? true,
      achievementNotifications: data['achievementNotifications'] ?? true,
      levelUpNotifications: data['levelUpNotifications'] ?? true,
      milestoneNotifications: data['milestoneNotifications'] ?? true,
      badgeNotifications: data['badgeNotifications'] ?? true,
      progressUpdates: data['progressUpdates'] ?? true,
      weeklyReports: data['weeklyReports'] ?? true,
      monthlyReports: data['monthlyReports'] ?? false,
      goalAchievements: data['goalAchievements'] ?? true,
      friendRequests: data['friendRequests'] ?? true,
      friendActivity: data['friendActivity'] ?? false,
      leaderboardUpdates: data['leaderboardUpdates'] ?? true,
      challengeInvites: data['challengeInvites'] ?? true,
      quietHoursEnabled: data['quietHoursEnabled'] ?? false,
      quietHoursStartHour: data['quietHoursStart']?['hour'] ?? 22,
      quietHoursStartMinute: data['quietHoursStart']?['minute'] ?? 0,
      quietHoursEndHour: data['quietHoursEnd']?['hour'] ?? 8,
      quietHoursEndMinute: data['quietHoursEnd']?['minute'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'ledEnabled': ledEnabled,
      'studyReminders': studyReminders,
      'goalReminders': goalReminders,
      'streakReminders': streakReminders,
      'breakReminders': breakReminders,
      'achievementNotifications': achievementNotifications,
      'levelUpNotifications': levelUpNotifications,
      'milestoneNotifications': milestoneNotifications,
      'badgeNotifications': badgeNotifications,
      'progressUpdates': progressUpdates,
      'weeklyReports': weeklyReports,
      'monthlyReports': monthlyReports,
      'goalAchievements': goalAchievements,
      'friendRequests': friendRequests,
      'friendActivity': friendActivity,
      'leaderboardUpdates': leaderboardUpdates,
      'challengeInvites': challengeInvites,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': {
        'hour': quietHoursStartHour,
        'minute': quietHoursStartMinute,
      },
      'quietHoursEnd': {
        'hour': quietHoursEndHour,
        'minute': quietHoursEndMinute,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
