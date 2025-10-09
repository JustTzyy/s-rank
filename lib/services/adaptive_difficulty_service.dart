import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdaptiveDifficultyService {
  static AdaptiveDifficultyService? _instance;
  
  factory AdaptiveDifficultyService() {
    _instance ??= AdaptiveDifficultyService._internal();
    return _instance!;
  }
  
  AdaptiveDifficultyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Adjust difficulty based on user performance
  Future<int> adjustDifficulty({
    required String flashcardId,
    required int currentDifficulty,
    required bool isCorrect,
    required Duration timeSpent,
    required String rating, // 'again', 'hard', 'good', 'easy'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return currentDifficulty;

      // Adaptive difficulty is always enabled

      // Get user's performance history for this card
      final performanceHistory = await _getPerformanceHistory(flashcardId);
      
      // Calculate new difficulty based on performance
      int newDifficulty = _calculateNewDifficulty(
        currentDifficulty: currentDifficulty,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
        rating: rating,
        performanceHistory: performanceHistory,
      );

      // Ensure difficulty stays within bounds (1-5)
      newDifficulty = newDifficulty.clamp(1, 5);

      // Update the card's difficulty
      await _updateCardDifficulty(flashcardId, newDifficulty);

      // Record this performance for future adjustments
      await _recordPerformance(
        flashcardId: flashcardId,
        difficulty: currentDifficulty,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
        rating: rating,
      );

      return newDifficulty;
    } catch (e) {
      print('Error adjusting difficulty: $e');
      return currentDifficulty;
    }
  }

  // Calculate new difficulty based on performance
  int _calculateNewDifficulty({
    required int currentDifficulty,
    required bool isCorrect,
    required Duration timeSpent,
    required String rating,
    required List<PerformanceRecord> performanceHistory,
  }) {
    double difficultyChange = 0.0;

    // Base adjustment on correctness
    if (isCorrect) {
      // Correct answer - consider increasing difficulty
      switch (rating) {
        case 'easy':
          difficultyChange = 0.3; // Increase difficulty more
          break;
        case 'good':
          difficultyChange = 0.1; // Slight increase
          break;
        case 'hard':
          difficultyChange = -0.1; // Slight decrease
          break;
        case 'again':
          difficultyChange = -0.3; // Decrease difficulty
          break;
      }
    } else {
      // Incorrect answer - decrease difficulty
      difficultyChange = -0.4;
    }

    // Adjust based on time spent (faster = easier, slower = harder)
    final timeInSeconds = timeSpent.inSeconds;
    if (timeInSeconds < 5) {
      difficultyChange += 0.1; // Very fast - might be too easy
    } else if (timeInSeconds > 30) {
      difficultyChange -= 0.1; // Very slow - might be too hard
    }

    // Consider recent performance history
    if (performanceHistory.length >= 3) {
      final recentPerformance = performanceHistory.take(3).toList();
      final recentAccuracy = recentPerformance.where((p) => p.isCorrect).length / recentPerformance.length;
      
      if (recentAccuracy > 0.8) {
        difficultyChange += 0.2; // High recent accuracy - increase difficulty
      } else if (recentAccuracy < 0.4) {
        difficultyChange -= 0.2; // Low recent accuracy - decrease difficulty
      }
    }

    // Apply the change
    final newDifficulty = currentDifficulty + difficultyChange;
    return newDifficulty.round();
  }

  // Get performance history for a specific card
  Future<List<PerformanceRecord>> _getPerformanceHistory(String flashcardId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cardPerformance')
          .where('flashcardId', isEqualTo: flashcardId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return query.docs.map((doc) => PerformanceRecord.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting performance history: $e');
      return [];
    }
  }

  // Record performance for future analysis
  Future<void> _recordPerformance({
    required String flashcardId,
    required int difficulty,
    required bool isCorrect,
    required Duration timeSpent,
    required String rating,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cardPerformance')
          .add({
        'flashcardId': flashcardId,
        'difficulty': difficulty,
        'isCorrect': isCorrect,
        'timeSpent': timeSpent.inSeconds,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording performance: $e');
    }
  }

  // Update card difficulty in the database
  Future<void> _updateCardDifficulty(String flashcardId, int newDifficulty) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update in user's personal card collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalizedCards')
          .doc(flashcardId)
          .set({
        'difficulty': newDifficulty,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating card difficulty: $e');
    }
  }

  // Get personalized difficulty for a card
  Future<int> getPersonalizedDifficulty(String flashcardId, int defaultDifficulty) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return defaultDifficulty;

      // Adaptive difficulty is always enabled

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalizedCards')
          .doc(flashcardId)
          .get();

      if (doc.exists) {
        return doc.data()?['difficulty'] ?? defaultDifficulty;
      }

      return defaultDifficulty;
    } catch (e) {
      print('Error getting personalized difficulty: $e');
      return defaultDifficulty;
    }
  }

  // Analyze user's overall performance patterns
  Future<PerformanceAnalysis> analyzePerformance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return PerformanceAnalysis();

      // Get recent performance data
      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cardPerformance')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (query.docs.isEmpty) return PerformanceAnalysis();

      final performances = query.docs.map((doc) => PerformanceRecord.fromMap(doc.data())).toList();
      
      return _analyzePerformanceData(performances);
    } catch (e) {
      print('Error analyzing performance: $e');
      return PerformanceAnalysis();
    }
  }

  // Analyze performance data to provide insights
  PerformanceAnalysis _analyzePerformanceData(List<PerformanceRecord> performances) {
    if (performances.isEmpty) return PerformanceAnalysis();

    // Calculate overall accuracy
    final correctCount = performances.where((p) => p.isCorrect).length;
    final overallAccuracy = correctCount / performances.length;

    // Calculate average time per card
    final totalTime = performances.fold<int>(0, (sum, p) => sum + p.timeSpent);
    final averageTime = totalTime / performances.length;

    // Analyze by difficulty level
    final Map<int, List<PerformanceRecord>> byDifficulty = {};
    for (final performance in performances) {
      byDifficulty.putIfAbsent(performance.difficulty, () => []).add(performance);
    }

    final Map<int, double> accuracyByDifficulty = {};
    final Map<int, double> averageTimeByDifficulty = {};

    for (final entry in byDifficulty.entries) {
      final difficulty = entry.key;
      final records = entry.value;
      
      final correct = records.where((r) => r.isCorrect).length;
      accuracyByDifficulty[difficulty] = correct / records.length;
      
      final totalTime = records.fold<int>(0, (sum, r) => sum + r.timeSpent);
      averageTimeByDifficulty[difficulty] = totalTime / records.length;
    }

    // Find optimal difficulty range
    int optimalDifficulty = 3; // Default to medium
    double bestAccuracy = 0.0;
    
    for (final entry in accuracyByDifficulty.entries) {
      if (entry.value > bestAccuracy && entry.value >= 0.6 && entry.value <= 0.8) {
        bestAccuracy = entry.value;
        optimalDifficulty = entry.key;
      }
    }

    // Calculate learning velocity (cards per minute)
    final totalCards = performances.length;
    final totalMinutes = totalTime / 60.0;
    final learningVelocity = totalMinutes > 0 ? totalCards / totalMinutes : 0.0;

    return PerformanceAnalysis(
      overallAccuracy: overallAccuracy,
      averageTimePerCard: averageTime,
      accuracyByDifficulty: accuracyByDifficulty,
      averageTimeByDifficulty: averageTimeByDifficulty,
      optimalDifficulty: optimalDifficulty,
      learningVelocity: learningVelocity,
      totalCardsAnalyzed: performances.length,
    );
  }

  // Get difficulty recommendations for new cards
  Future<int> getRecommendedDifficulty() async {
    try {
      final analysis = await analyzePerformance();
      return analysis.optimalDifficulty;
    } catch (e) {
      print('Error getting recommended difficulty: $e');
      return 3; // Default to medium
    }
  }

  // Reset adaptive difficulty for a user
  Future<void> resetAdaptiveDifficulty() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Clear all personalized card difficulties
      final batch = _firestore.batch();
      final personalizedCards = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personalizedCards')
          .get();

      for (final doc in personalizedCards.docs) {
        batch.delete(doc.reference);
      }

      // Clear performance history
      final performanceHistory = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cardPerformance')
          .get();

      for (final doc in performanceHistory.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error resetting adaptive difficulty: $e');
    }
  }
}

// Data models
class PerformanceRecord {
  final String flashcardId;
  final int difficulty;
  final bool isCorrect;
  final int timeSpent; // in seconds
  final String rating;
  final DateTime timestamp;

  PerformanceRecord({
    required this.flashcardId,
    required this.difficulty,
    required this.isCorrect,
    required this.timeSpent,
    required this.rating,
    required this.timestamp,
  });

  factory PerformanceRecord.fromMap(Map<String, dynamic> data) {
    return PerformanceRecord(
      flashcardId: data['flashcardId'] ?? '',
      difficulty: data['difficulty'] ?? 3,
      isCorrect: data['isCorrect'] ?? false,
      timeSpent: (data['timeSpent'] as int?) ?? 0,
      rating: data['rating'] ?? 'good',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class PerformanceAnalysis {
  final double overallAccuracy;
  final double averageTimePerCard;
  final Map<int, double> accuracyByDifficulty;
  final Map<int, double> averageTimeByDifficulty;
  final int optimalDifficulty;
  final double learningVelocity;
  final int totalCardsAnalyzed;

  PerformanceAnalysis({
    this.overallAccuracy = 0.0,
    this.averageTimePerCard = 0.0,
    this.accuracyByDifficulty = const {},
    this.averageTimeByDifficulty = const {},
    this.optimalDifficulty = 3,
    this.learningVelocity = 0.0,
    this.totalCardsAnalyzed = 0,
  });

  String get performanceLevel {
    if (overallAccuracy >= 0.8) return 'Excellent';
    if (overallAccuracy >= 0.7) return 'Good';
    if (overallAccuracy >= 0.6) return 'Fair';
    return 'Needs Improvement';
  }

  String get timeEfficiency {
    if (averageTimePerCard <= 10) return 'Very Fast';
    if (averageTimePerCard <= 20) return 'Fast';
    if (averageTimePerCard <= 30) return 'Normal';
    return 'Slow';
  }

  List<String> get recommendations {
    final List<String> recs = [];
    
    if (overallAccuracy < 0.6) {
      recs.add('Consider reviewing easier cards to build confidence');
    } else if (overallAccuracy > 0.9) {
      recs.add('You\'re doing great! Try more challenging cards');
    }
    
    if (averageTimePerCard > 30) {
      recs.add('Try to answer cards more quickly to improve efficiency');
    }
    
    if (learningVelocity < 2) {
      recs.add('Consider shorter, more frequent study sessions');
    }
    
    return recs;
  }
}
