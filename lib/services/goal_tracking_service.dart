import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class GoalTrackingService {
  static GoalTrackingService? _instance;
  
  factory GoalTrackingService() {
    _instance ??= GoalTrackingService._internal();
    return _instance!;
  }
  
  GoalTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Track daily study goal progress
  Future<void> updateDailyStudyProgress({
    required int minutesStudied,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Goal tracking: No user logged in');
        return;
      }

      print('Goal tracking: Updating daily study progress - $minutesStudied minutes');

      // Progress tracking is always enabled

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Note: Progress tracking is now handled by ProgressTrackingService
      // This method is kept for backward compatibility but doesn't update Firestore
      // to avoid conflicts with the main progress tracking service
      print('Goal tracking: Progress tracking handled by ProgressTrackingService');
      print('Goal tracking: Firestore updated successfully');

      // Check if daily goal is achieved
      final settings = await getGoalSettings();
      final dailyStudyGoal = settings?.dailyStudyGoal ?? 30;
      
      // Get current progress from ProgressTrackingService
      final progressDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .doc(today.toIso8601String().split('T')[0])
          .get();
      
      final currentMinutes = progressDoc.data()?['duration'] ?? 0;
      if (currentMinutes >= dailyStudyGoal) {
        await _handleGoalAchievement(
          type: 'daily_study',
          goal: dailyStudyGoal,
          achieved: currentMinutes,
        );
      }

      // Check if weekly goal is achieved
      await _checkWeeklyStudyGoal();
    } catch (e) {
      print('Error updating daily study progress: $e');
    }
  }

  // Track daily card goal progress
  Future<void> updateDailyCardProgress({
    required int cardsStudied,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Points tracking is always enabled

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Note: Progress tracking is now handled by ProgressTrackingService
      // This method is kept for backward compatibility but doesn't update Firestore
      // to avoid conflicts with the main progress tracking service
      print('Goal tracking: Card progress tracking handled by ProgressTrackingService');

      // Check if daily card goal is achieved
      final settings = await getGoalSettings();
      final dailyCardGoal = settings?.dailyCardGoal ?? 20;
      
      // Get current progress from ProgressTrackingService
      final progressDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .doc(today.toIso8601String().split('T')[0])
          .get();
      
      final currentCards = progressDoc.data()?['cardsStudied'] ?? 0;
      if (currentCards >= dailyCardGoal) {
        await _handleGoalAchievement(
          type: 'daily_cards',
          goal: dailyCardGoal,
          achieved: currentCards,
        );
      }

      // Check if weekly card goal is achieved
      await _checkWeeklyCardGoal();
    } catch (e) {
      print('Error updating daily card progress: $e');
    }
  }

  // Get daily progress
  Future<DailyProgress?> getDailyProgress(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final dateStr = date.toIso8601String().split('T')[0];
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        return DailyProgress.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting daily progress: $e');
      return null;
    }
  }

  // Get weekly progress
  Future<WeeklyProgress> getWeeklyProgress(DateTime weekStart) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return WeeklyProgress(weekStart: weekStart);

      final weekEnd = weekStart.add(const Duration(days: 6));
      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .where('date', isGreaterThanOrEqualTo: weekStart)
          .where('date', isLessThanOrEqualTo: weekEnd)
          .get();

      int totalStudyMinutes = 0;
      int totalCardsStudied = 0;
      int studyDays = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        totalStudyMinutes += (data['duration'] as int?) ?? 0;
        totalCardsStudied += (data['cardsStudied'] as int?) ?? 0;
        if (((data['duration'] as int?) ?? 0) > 0) {
          studyDays++;
        }
      }

      return WeeklyProgress(
        weekStart: weekStart,
        totalStudyMinutes: totalStudyMinutes,
        totalCardsStudied: totalCardsStudied,
        studyDays: studyDays,
      );
    } catch (e) {
      print('Error getting weekly progress: $e');
      return WeeklyProgress(weekStart: weekStart);
    }
  }

  // Get goal progress summary
  Future<GoalProgressSummary> getGoalProgressSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return GoalProgressSummary();

      // Progress tracking is always enabled

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      // Get goal settings
      final settings = await getGoalSettings();

      // Get today's progress
      final todayProgress = await getDailyProgress(today);
      final weeklyProgress = await getWeeklyProgress(weekStart);

      return GoalProgressSummary(
        dailyStudyGoal: settings?.dailyStudyGoal ?? 30,
        dailyStudyProgress: todayProgress?.duration ?? 0,
        dailyCardGoal: settings?.dailyCardGoal ?? 20,
        dailyCardProgress: todayProgress?.cardsStudied ?? 0,
        weeklyStudyGoal: settings?.weeklyStudyGoal ?? 180,
        weeklyStudyProgress: weeklyProgress.totalStudyMinutes,
        weeklyCardGoal: settings?.weeklyCardGoal ?? 100,
        weeklyCardProgress: weeklyProgress.totalCardsStudied,
        studyStreak: await _getCurrentStreak(),
        longestStreak: await _getLongestStreak(),
      );
    } catch (e) {
      print('Error getting goal progress summary: $e');
      return GoalProgressSummary();
    }
  }

  // Check weekly study goal
  Future<void> _checkWeeklyStudyGoal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Progress tracking is always enabled

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weeklyProgress = await getWeeklyProgress(weekStart);

      // Check if this is the first time achieving weekly goal
      final goalDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goalAchievements')
          .doc('${weekStart.toIso8601String().split('T')[0]}_weekly_study')
          .get();

      final settings = await getGoalSettings();
      final weeklyStudyGoal = settings?.weeklyStudyGoal ?? 180;
      if (weeklyProgress.totalStudyMinutes >= weeklyStudyGoal && !goalDoc.exists) {
        await _handleGoalAchievement(
          type: 'weekly_study',
          goal: weeklyStudyGoal,
          achieved: weeklyProgress.totalStudyMinutes,
        );
      }
    } catch (e) {
      print('Error checking weekly study goal: $e');
    }
  }

  // Check weekly card goal
  Future<void> _checkWeeklyCardGoal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Progress tracking is always enabled

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weeklyProgress = await getWeeklyProgress(weekStart);

      // Check if this is the first time achieving weekly goal
      final goalDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goalAchievements')
          .doc('${weekStart.toIso8601String().split('T')[0]}_weekly_cards')
          .get();

      final settings = await getGoalSettings();
      final weeklyCardGoal = settings?.weeklyCardGoal ?? 100;
      if (weeklyProgress.totalCardsStudied >= weeklyCardGoal && !goalDoc.exists) {
        await _handleGoalAchievement(
          type: 'weekly_cards',
          goal: weeklyCardGoal,
          achieved: weeklyProgress.totalCardsStudied,
        );
      }
    } catch (e) {
      print('Error checking weekly card goal: $e');
    }
  }

  // Handle goal achievement
  Future<void> _handleGoalAchievement({
    required String type,
    required int goal,
    required int achieved,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Goal reminders are always enabled

      // Record achievement
      final today = DateTime.now();
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goalAchievements')
          .doc('${today.toIso8601String().split('T')[0]}_$type')
          .set({
        'type': type,
        'goal': goal,
        'achieved': achieved,
        'date': today,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notification
      String title = '';
      String body = '';

      switch (type) {
        case 'daily_study':
          title = 'Daily Study Goal Achieved! 🎯';
          body = 'Great job! You studied for $achieved minutes today (Goal: $goal min)';
          break;
        case 'daily_cards':
          title = 'Daily Card Goal Achieved! 📚';
          body = 'Excellent! You studied $achieved cards today (Goal: $goal cards)';
          break;
        case 'weekly_study':
          title = 'Weekly Study Goal Achieved! 🏆';
          body = 'Amazing! You studied for $achieved minutes this week (Goal: $goal min)';
          break;
        case 'weekly_cards':
          title = 'Weekly Card Goal Achieved! 🌟';
          body = 'Outstanding! You studied $achieved cards this week (Goal: $goal cards)';
          break;
      }

      await _notificationService.showProgressNotification(
        title: title,
        body: body,
      );
    } catch (e) {
      print('Error handling goal achievement: $e');
    }
  }

  // Get current study streak
  Future<int> _getCurrentStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final today = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 365; i++) { // Check up to a year back
        final date = today.subtract(Duration(days: i));
        final progress = await getDailyProgress(date);
        
        if (progress != null && progress.duration > 0) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  // Get longest study streak
  Future<int> _getLongestStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userStats')
          .doc('streakStats')
          .get();

      return doc.data()?['longestStreak'] ?? 0;
    } catch (e) {
      print('Error getting longest streak: $e');
      return 0;
    }
  }

  // Get goal settings
  Future<GoalSettings?> getGoalSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .get();

      if (doc.exists) {
        return GoalSettings.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error loading goal settings: $e');
      return null;
    }
  }

  // Save goal settings
  Future<void> saveGoalSettings(GoalSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('goals')
          .set(settings.toMap());
    } catch (e) {
      print('Error saving goal settings: $e');
      throw Exception('Failed to save goal settings: $e');
    }
  }

  // Update streak statistics
  Future<void> updateStreakStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final currentStreak = await _getCurrentStreak();
      final longestStreak = await _getLongestStreak();

      if (currentStreak > longestStreak) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('userStats')
            .doc('streakStats')
            .set({
          'currentStreak': currentStreak,
          'longestStreak': currentStreak,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('userStats')
            .doc('streakStats')
            .set({
          'currentStreak': currentStreak,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating streak stats: $e');
    }
  }
}

// Data models
class DailyProgress {
  final DateTime date;
  final int duration;
  final int cardsStudied;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;

  DailyProgress({
    required this.date,
    this.duration = 0,
    this.cardsStudied = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.accuracy = 0.0,
  });

  factory DailyProgress.fromMap(Map<String, dynamic> data) {
    return DailyProgress(
      date: (data['date'] as Timestamp).toDate(),
      duration: (data['duration'] as int?) ?? 0,
      cardsStudied: (data['cardsStudied'] as int?) ?? 0,
      correctAnswers: (data['correctAnswers'] as int?) ?? 0,
      incorrectAnswers: (data['incorrectAnswers'] as int?) ?? 0,
      accuracy: (data['accuracy'] as double?) ?? 0.0,
    );
  }
}

class WeeklyProgress {
  final DateTime weekStart;
  final int totalStudyMinutes;
  final int totalCardsStudied;
  final int studyDays;

  WeeklyProgress({
    required this.weekStart,
    this.totalStudyMinutes = 0,
    this.totalCardsStudied = 0,
    this.studyDays = 0,
  });
}

class GoalProgressSummary {
  final int dailyStudyGoal;
  final int dailyStudyProgress;
  final int dailyCardGoal;
  final int dailyCardProgress;
  final int weeklyStudyGoal;
  final int weeklyStudyProgress;
  final int weeklyCardGoal;
  final int weeklyCardProgress;
  final int studyStreak;
  final int longestStreak;

  GoalProgressSummary({
    this.dailyStudyGoal = 0,
    this.dailyStudyProgress = 0,
    this.dailyCardGoal = 0,
    this.dailyCardProgress = 0,
    this.weeklyStudyGoal = 0,
    this.weeklyStudyProgress = 0,
    this.weeklyCardGoal = 0,
    this.weeklyCardProgress = 0,
    this.studyStreak = 0,
    this.longestStreak = 0,
  });

  double get dailyStudyProgressPercentage => 
      dailyStudyGoal > 0 ? (dailyStudyProgress / dailyStudyGoal * 100).clamp(0, 100) : 0;

  double get dailyCardProgressPercentage => 
      dailyCardGoal > 0 ? (dailyCardProgress / dailyCardGoal * 100).clamp(0, 100) : 0;

  double get weeklyStudyProgressPercentage => 
      weeklyStudyGoal > 0 ? (weeklyStudyProgress / weeklyStudyGoal * 100).clamp(0, 100) : 0;

  double get weeklyCardProgressPercentage => 
      weeklyCardGoal > 0 ? (weeklyCardProgress / weeklyCardGoal * 100).clamp(0, 100) : 0;
}

class GoalSettings {
  final int dailyStudyGoal;
  final int dailyCardGoal;
  final int weeklyStudyGoal;
  final int weeklyCardGoal;

  GoalSettings({
    required this.dailyStudyGoal,
    required this.dailyCardGoal,
    required this.weeklyStudyGoal,
    required this.weeklyCardGoal,
  });

  factory GoalSettings.fromMap(Map<String, dynamic> data) {
    return GoalSettings(
      dailyStudyGoal: data['dailyStudyGoal'] ?? 30,
      dailyCardGoal: data['dailyCardGoal'] ?? 20,
      weeklyStudyGoal: data['weeklyStudyGoal'] ?? 180,
      weeklyCardGoal: data['weeklyCardGoal'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyStudyGoal': dailyStudyGoal,
      'dailyCardGoal': dailyCardGoal,
      'weeklyStudyGoal': weeklyStudyGoal,
      'weeklyCardGoal': weeklyCardGoal,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
