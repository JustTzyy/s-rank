import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/preferences_service.dart';
import '../services/privacy_service.dart';

class ProgressTrackingService {
  static ProgressTrackingService? _instance;
  
  factory ProgressTrackingService() {
    _instance ??= ProgressTrackingService._internal();
    return _instance!;
  }
  
  ProgressTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PreferencesService _preferencesService = PreferencesService();
  final PrivacyService _privacyService = PrivacyService();

  // Track study session progress
  Future<void> trackStudySession({
    required String deckId,
    required int duration, // in minutes
    required int cardsStudied,
    required int correctAnswers,
    required int incorrectAnswers,
    required double accuracy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check privacy settings first
      final canCollectStudyData = await _privacyService.canCollectStudyData();
      if (!canCollectStudyData) return;

      final settings = await _preferencesService.getProgressSettings();
      if (settings == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Update daily progress
      await _updateDailyProgress(
        userId: user.uid,
        date: today,
        duration: settings.trackStudyTime ? duration : 0,
        cardsStudied: cardsStudied,
        correctAnswers: settings.trackAccuracy ? correctAnswers : 0,
        incorrectAnswers: settings.trackAccuracy ? incorrectAnswers : 0,
        accuracy: settings.trackAccuracy ? accuracy : 0.0,
      );

      // Update weekly progress
      await _updateWeeklyProgress(
        userId: user.uid,
        weekStart: _getWeekStart(today),
        duration: settings.trackStudyTime ? duration : 0,
        cardsStudied: cardsStudied,
        correctAnswers: settings.trackAccuracy ? correctAnswers : 0,
        incorrectAnswers: settings.trackAccuracy ? incorrectAnswers : 0,
        accuracy: settings.trackAccuracy ? accuracy : 0.0,
      );

      // Update deck progress
      await _updateDeckProgress(
        userId: user.uid,
        deckId: deckId,
        cardsStudied: cardsStudied,
        correctAnswers: settings.trackAccuracy ? correctAnswers : 0,
        incorrectAnswers: settings.trackAccuracy ? incorrectAnswers : 0,
        accuracy: settings.trackAccuracy ? accuracy : 0.0,
      );

      // Update user points if tracking is enabled
      if (settings.trackPoints) {
        await _updateUserPoints(user.uid, correctAnswers, duration);
      }

      // Update study streak if tracking is enabled
      if (settings.trackStreaks) {
        await _updateStudyStreak(user.uid, today);
      }
    } catch (e) {
      print('Error tracking study session: $e');
    }
  }

  // Get daily progress
  Future<DailyProgress?> getDailyProgress(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .doc(_formatDate(date))
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
  Future<WeeklyProgress?> getWeeklyProgress(DateTime weekStart) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyProgress')
          .doc(_formatDate(weekStart))
          .get();

      if (doc.exists) {
        return WeeklyProgress.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting weekly progress: $e');
      return null;
    }
  }

  // Get study streak
  Future<int> getStudyStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('studyStreak')
          .doc('current')
          .get();

      if (doc.exists) {
        return doc.data()?['currentStreak'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting study streak: $e');
      return 0;
    }
  }

  // Get goal progress
  Future<GoalProgress> getGoalProgress() async {
    try {
      final user = _auth.currentUser;
      final settings = await _preferencesService.getProgressSettings();
      if (user == null || settings == null) {
        return GoalProgress.empty();
      }

      final today = DateTime.now();
      final dailyProgress = await getDailyProgress(today);
      final weeklyProgress = await getWeeklyProgress(_getWeekStart(today));

      return GoalProgress(
        dailyStudyGoal: settings.dailyStudyGoal,
        dailyStudyProgress: dailyProgress?.duration ?? 0,
        dailyCardGoal: settings.dailyCardGoal,
        dailyCardProgress: dailyProgress?.cardsStudied ?? 0,
        weeklyStudyGoal: settings.weeklyStudyGoal,
        weeklyStudyProgress: weeklyProgress?.duration ?? 0,
        weeklyCardGoal: settings.weeklyCardGoal,
        weeklyCardProgress: weeklyProgress?.cardsStudied ?? 0,
      );
    } catch (e) {
      print('Error getting goal progress: $e');
      return GoalProgress.empty();
    }
  }

  // Private helper methods
  Future<void> _updateDailyProgress({
    required String userId,
    required DateTime date,
    required int duration,
    required int cardsStudied,
    required int correctAnswers,
    required int incorrectAnswers,
    required double accuracy,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyProgress')
        .doc(_formatDate(date));

    await docRef.set({
      'date': Timestamp.fromDate(date),
      'duration': FieldValue.increment(duration),
      'cardsStudied': FieldValue.increment(cardsStudied),
      'correctAnswers': FieldValue.increment(correctAnswers),
      'incorrectAnswers': FieldValue.increment(incorrectAnswers),
      'accuracy': accuracy, // This will be recalculated
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateWeeklyProgress({
    required String userId,
    required DateTime weekStart,
    required int duration,
    required int cardsStudied,
    required int correctAnswers,
    required int incorrectAnswers,
    required double accuracy,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('weeklyProgress')
        .doc(_formatDate(weekStart));

    await docRef.set({
      'weekStart': Timestamp.fromDate(weekStart),
      'duration': FieldValue.increment(duration),
      'cardsStudied': FieldValue.increment(cardsStudied),
      'correctAnswers': FieldValue.increment(correctAnswers),
      'incorrectAnswers': FieldValue.increment(incorrectAnswers),
      'accuracy': accuracy, // This will be recalculated
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateDeckProgress({
    required String userId,
    required String deckId,
    required int cardsStudied,
    required int correctAnswers,
    required int incorrectAnswers,
    required double accuracy,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('deckProgress')
        .doc(deckId);

    await docRef.set({
      'deckId': deckId,
      'totalCardsStudied': FieldValue.increment(cardsStudied),
      'totalCorrectAnswers': FieldValue.increment(correctAnswers),
      'totalIncorrectAnswers': FieldValue.increment(incorrectAnswers),
      'overallAccuracy': accuracy, // This will be recalculated
      'lastStudied': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateUserPoints(String userId, int correctAnswers, int duration) async {
    // Award points based on correct answers and study time
    final points = (correctAnswers * 10) + (duration * 2);
    
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateStudyStreak(String userId, DateTime date) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('studyStreak')
        .doc('current');
    
    final streakDoc = await docRef.get();
    
    if (streakDoc.exists) {
      final data = streakDoc.data()!;
      final lastStudyDate = (data['lastStudyDate'] as Timestamp?)?.toDate();
      final currentStreak = data['currentStreak'] ?? 0;
      
      if (lastStudyDate != null) {
        final daysDifference = date.difference(lastStudyDate).inDays;
        
        if (daysDifference == 1) {
          // Consecutive day - increment streak
          await docRef.update({
            'currentStreak': currentStreak + 1,
            'lastStudyDate': Timestamp.fromDate(date),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (daysDifference > 1) {
          // Streak broken - reset to 1
          await docRef.update({
            'currentStreak': 1,
            'lastStudyDate': Timestamp.fromDate(date),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        // If daysDifference == 0, it's the same day, don't update
      } else {
        // First study session
        await docRef.set({
          'currentStreak': 1,
          'lastStudyDate': Timestamp.fromDate(date),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // First study session - create document
      await docRef.set({
        'currentStreak': 1,
        'lastStudyDate': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class DailyProgress {
  final DateTime date;
  final int duration;
  final int cardsStudied;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;

  DailyProgress({
    required this.date,
    required this.duration,
    required this.cardsStudied,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
  });

  factory DailyProgress.fromMap(Map<String, dynamic> data) {
    return DailyProgress(
      date: (data['date'] as Timestamp).toDate(),
      duration: data['duration'] ?? 0,
      cardsStudied: data['cardsStudied'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      incorrectAnswers: data['incorrectAnswers'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
    );
  }
}

class WeeklyProgress {
  final DateTime weekStart;
  final int duration;
  final int cardsStudied;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;

  WeeklyProgress({
    required this.weekStart,
    required this.duration,
    required this.cardsStudied,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
  });

  factory WeeklyProgress.fromMap(Map<String, dynamic> data) {
    return WeeklyProgress(
      weekStart: (data['weekStart'] as Timestamp).toDate(),
      duration: data['duration'] ?? 0,
      cardsStudied: data['cardsStudied'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      incorrectAnswers: data['incorrectAnswers'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
    );
  }
}

class GoalProgress {
  final int dailyStudyGoal;
  final int dailyStudyProgress;
  final int dailyCardGoal;
  final int dailyCardProgress;
  final int weeklyStudyGoal;
  final int weeklyStudyProgress;
  final int weeklyCardGoal;
  final int weeklyCardProgress;

  GoalProgress({
    required this.dailyStudyGoal,
    required this.dailyStudyProgress,
    required this.dailyCardGoal,
    required this.dailyCardProgress,
    required this.weeklyStudyGoal,
    required this.weeklyStudyProgress,
    required this.weeklyCardGoal,
    required this.weeklyCardProgress,
  });

  factory GoalProgress.empty() {
    return GoalProgress(
      dailyStudyGoal: 0,
      dailyStudyProgress: 0,
      dailyCardGoal: 0,
      dailyCardProgress: 0,
      weeklyStudyGoal: 0,
      weeklyStudyProgress: 0,
      weeklyCardGoal: 0,
      weeklyCardProgress: 0,
    );
  }

  double get dailyStudyProgressPercentage {
    if (dailyStudyGoal == 0) return 0.0;
    return (dailyStudyProgress / dailyStudyGoal).clamp(0.0, 1.0);
  }

  double get dailyCardProgressPercentage {
    if (dailyCardGoal == 0) return 0.0;
    return (dailyCardProgress / dailyCardGoal).clamp(0.0, 1.0);
  }

  double get weeklyStudyProgressPercentage {
    if (weeklyStudyGoal == 0) return 0.0;
    return (weeklyStudyProgress / weeklyStudyGoal).clamp(0.0, 1.0);
  }

  double get weeklyCardProgressPercentage {
    if (weeklyCardGoal == 0) return 0.0;
    return (weeklyCardProgress / weeklyCardGoal).clamp(0.0, 1.0);
  }
}
