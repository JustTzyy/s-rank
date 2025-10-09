import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_tracking_service.dart';

class ProgressTrackingService {
  static ProgressTrackingService? _instance;
  
  factory ProgressTrackingService() {
    _instance ??= ProgressTrackingService._internal();
    return _instance!;
  }
  
  ProgressTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoalTrackingService _goalTrackingService = GoalTrackingService();

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
      if (user == null) {
        print('Progress tracking: No user logged in');
        return;
      }

      print('Progress tracking: Starting session tracking');
      print('Duration: $duration minutes, Cards: $cardsStudied, Correct: $correctAnswers, Incorrect: $incorrectAnswers');

      // Check privacy settings first
      // Privacy service removed - assume data collection is allowed
      final canCollectStudyData = true;
      if (!canCollectStudyData) return;

      // Progress tracking is always enabled

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Update daily progress (all tracking is always enabled)
      await _updateDailyProgress(
        userId: user.uid,
        date: today,
        duration: duration,
        cardsStudied: cardsStudied,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        accuracy: accuracy,
      );

      // Update goal tracking (always enabled)
      print('Progress tracking: Updating goal tracking');
      await _goalTrackingService.updateDailyStudyProgress(minutesStudied: duration);
      await _goalTrackingService.updateDailyCardProgress(cardsStudied: cardsStudied);
      print('Progress tracking: Goal tracking updated');

      // Update weekly progress (all tracking is always enabled)
      await _updateWeeklyProgress(
        userId: user.uid,
        weekStart: _getWeekStart(today),
        duration: duration,
        cardsStudied: cardsStudied,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        accuracy: accuracy,
      );

      // Update deck progress (all tracking is always enabled)
      await _updateDeckProgress(
        userId: user.uid,
        deckId: deckId,
        cardsStudied: cardsStudied,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        accuracy: accuracy,
      );

      // Update user points (always enabled)
      await _updateUserPoints(user.uid, correctAnswers, duration);

      // Update study streak (always enabled)
      await _updateStudyStreak(user.uid, today);
      print('Progress tracking: Session tracking completed successfully');
    } catch (e) {
      print('Error tracking study session: $e');
    }
  }

  // Get daily progress
  Future<DailyProgress?> getDailyProgress(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Progress tracking: No user logged in for getDailyProgress');
        return null;
      }

      final dateKey = _formatDate(date);

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return DailyProgress.fromMap(data);
      } else {
        return null;
      }
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
      if (user == null) {
        print('Progress tracking: No user logged in for getGoalProgress');
        return GoalProgress.empty();
      }

      final today = DateTime.now();
      
      final dailyProgress = await getDailyProgress(today);
      final weeklyProgress = await getWeeklyProgress(_getWeekStart(today));

      // Get goal settings
      final settings = await _goalTrackingService.getGoalSettings();

      final goalProgress = GoalProgress(
        dailyStudyGoal: settings?.dailyStudyGoal ?? 30,
        dailyStudyProgress: dailyProgress?.duration ?? 0,
        dailyCardGoal: settings?.dailyCardGoal ?? 20,
        dailyCardProgress: dailyProgress?.cardsStudied ?? 0,
        weeklyStudyGoal: settings?.weeklyStudyGoal ?? 180,
        weeklyStudyProgress: weeklyProgress?.duration ?? 0,
        weeklyCardGoal: settings?.weeklyCardGoal ?? 100,
        weeklyCardProgress: weeklyProgress?.cardsStudied ?? 0,
      );
      
      
      return goalProgress;
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
    final dateKey = _formatDate(date);
    
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyProgress')
        .doc(dateKey);

    // Get current values first to avoid conflicts with goal tracking service
    final currentDoc = await docRef.get();
    final currentData = currentDoc.data();
    
    final currentDuration = (currentData?['duration'] as int?) ?? 0;
    final currentCards = (currentData?['cardsStudied'] as int?) ?? 0;
    final currentCorrect = (currentData?['correctAnswers'] as int?) ?? 0;
    final currentIncorrect = (currentData?['incorrectAnswers'] as int?) ?? 0;
    
    final newDuration = currentDuration + duration;
    final newCards = currentCards + cardsStudied;
    
    
    await docRef.set({
      'date': Timestamp.fromDate(date),
      'duration': newDuration,
      'cardsStudied': newCards,
      'correctAnswers': currentCorrect + correctAnswers,
      'incorrectAnswers': currentIncorrect + incorrectAnswers,
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

    // Get current values first to avoid conflicts
    final currentDoc = await docRef.get();
    final currentData = currentDoc.data();
    
    final currentDuration = (currentData?['duration'] as int?) ?? 0;
    final currentCards = (currentData?['cardsStudied'] as int?) ?? 0;
    final currentCorrect = (currentData?['correctAnswers'] as int?) ?? 0;
    final currentIncorrect = (currentData?['incorrectAnswers'] as int?) ?? 0;
    
    await docRef.set({
      'weekStart': Timestamp.fromDate(weekStart),
      'duration': currentDuration + duration,
      'cardsStudied': currentCards + cardsStudied,
      'correctAnswers': currentCorrect + correctAnswers,
      'incorrectAnswers': currentIncorrect + incorrectAnswers,
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

    // Get current values first to avoid conflicts
    final currentDoc = await docRef.get();
    final currentData = currentDoc.data();
    
    final currentCards = (currentData?['totalCardsStudied'] as int?) ?? 0;
    final currentCorrect = (currentData?['totalCorrectAnswers'] as int?) ?? 0;
    final currentIncorrect = (currentData?['totalIncorrectAnswers'] as int?) ?? 0;
    
    await docRef.set({
      'deckId': deckId,
      'totalCardsStudied': currentCards + cardsStudied,
      'totalCorrectAnswers': currentCorrect + correctAnswers,
      'totalIncorrectAnswers': currentIncorrect + incorrectAnswers,
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
      final currentStreak = (data['currentStreak'] as int?) ?? 0;
      
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

  // Get daily history
  Future<List<DailyProgressHistory>> getDailyHistory(int days) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final today = DateTime.now();
      final List<DailyProgressHistory> history = [];
      
      
      // Get goal settings for consistent goal values
      final settings = await _goalTrackingService.getGoalSettings();

      // Use the same method as dashboard for consistency
      for (int i = 0; i < days; i++) {
        final date = today.subtract(Duration(days: i));
        final progress = await getDailyProgress(date);
        
        
        // Calculate study streak (simplified for single day)
        int streak = 0;
        if (progress != null && progress.duration > 0) {
          // For today, just check if there's any progress
          streak = 1;
        }

        history.add(DailyProgressHistory(
          date: date,
          duration: progress?.duration ?? 0,
          cardsStudied: progress?.cardsStudied ?? 0,
          correctAnswers: progress?.correctAnswers ?? 0,
          incorrectAnswers: progress?.incorrectAnswers ?? 0,
          accuracy: progress?.accuracy ?? 0.0,
          dailyStudyGoal: settings?.dailyStudyGoal ?? 30,
          dailyCardGoal: settings?.dailyCardGoal ?? 20,
          studyStreak: streak,
        ));
      }

      return history;
    } catch (e) {
      print('Error getting daily history: $e');
      return [];
    }
  }

  // Get weekly history
  Future<List<WeeklyProgressHistory>> getWeeklyHistory(int weeks) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final today = DateTime.now();
      final List<WeeklyProgressHistory> history = [];
      
      // Get goal settings for consistent goal values
      final settings = await _goalTrackingService.getGoalSettings();

      // Fetch daily progress data for the requested weeks
      final startDate = today.subtract(Duration(days: (today.weekday - 1) + ((weeks - 1) * 7)));
      final endDate = today;
      
      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      // Create a map for quick lookup
      final Map<String, DailyProgress> progressMap = {};
      for (final doc in query.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = _formatDate(date);
        
        progressMap[dateKey] = DailyProgress(
          date: date,
          duration: (data['duration'] as int?) ?? 0,
          cardsStudied: (data['cardsStudied'] as int?) ?? 0,
          correctAnswers: (data['correctAnswers'] as int?) ?? 0,
          incorrectAnswers: (data['incorrectAnswers'] as int?) ?? 0,
          accuracy: (data['accuracy'] as double?) ?? 0.0,
        );
      }

      for (int i = 0; i < weeks; i++) {
        final weekStart = today.subtract(Duration(days: (today.weekday - 1) + (i * 7)));
        final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
        
        // Get all daily progress for this week using the map
        int totalDuration = 0;
        int totalCards = 0;
        int totalCorrect = 0;
        int totalIncorrect = 0;
        int studyDays = 0;
        
        for (int day = 0; day < 7; day++) {
          final date = weekStartNormalized.add(Duration(days: day));
          final dateKey = _formatDate(date);
          final progress = progressMap[dateKey];
          
          if (progress != null) {
            totalDuration += progress.duration;
            totalCards += progress.cardsStudied;
            totalCorrect += progress.correctAnswers;
            totalIncorrect += progress.incorrectAnswers;
            
            if (progress.duration > 0) {
              studyDays++;
            }
          }
        }
        
        // Calculate average accuracy
        final totalAnswers = totalCorrect + totalIncorrect;
        final accuracy = totalAnswers > 0 ? (totalCorrect / totalAnswers) * 100 : 0.0;

        history.add(WeeklyProgressHistory(
          weekStart: weekStartNormalized,
          duration: totalDuration,
          cardsStudied: totalCards,
          correctAnswers: totalCorrect,
          incorrectAnswers: totalIncorrect,
          accuracy: accuracy,
          weeklyStudyGoal: settings?.weeklyStudyGoal ?? 180,
          weeklyCardGoal: settings?.weeklyCardGoal ?? 100,
          studyDays: studyDays,
        ));
      }

      return history;
    } catch (e) {
      print('Error getting weekly history: $e');
      return [];
    }
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
      duration: (data['duration'] as int?) ?? 0,
      cardsStudied: (data['cardsStudied'] as int?) ?? 0,
      correctAnswers: (data['correctAnswers'] as int?) ?? 0,
      incorrectAnswers: (data['incorrectAnswers'] as int?) ?? 0,
      accuracy: (data['accuracy'] as double?) ?? 0.0,
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

// History data models
class DailyProgressHistory {
  final DateTime date;
  final int duration;
  final int cardsStudied;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;
  final int dailyStudyGoal;
  final int dailyCardGoal;
  final int studyStreak;

  DailyProgressHistory({
    required this.date,
    required this.duration,
    required this.cardsStudied,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
    required this.dailyStudyGoal,
    required this.dailyCardGoal,
    required this.studyStreak,
  });
}

class WeeklyProgressHistory {
  final DateTime weekStart;
  final int duration;
  final int cardsStudied;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;
  final int weeklyStudyGoal;
  final int weeklyCardGoal;
  final int studyDays;

  WeeklyProgressHistory({
    required this.weekStart,
    required this.duration,
    required this.cardsStudied,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
    required this.weeklyStudyGoal,
    required this.weeklyCardGoal,
    required this.studyDays,
  });
}
