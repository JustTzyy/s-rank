import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeCompletion {
  final String? id;
  final String userId;
  final String courseId;
  final String deckId;
  final DateTime completedAt;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final Duration timeSpent;
  final int pointsEarned;

  ChallengeCompletion({
    this.id,
    required this.userId,
    required this.courseId,
    required this.deckId,
    required this.completedAt,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.timeSpent,
    required this.pointsEarned,
  });

  // Factory constructor from Firestore
  factory ChallengeCompletion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeCompletion(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      deckId: data['deckId'] ?? '',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
      timeSpent: Duration(seconds: data['timeSpentSeconds'] ?? 0),
      pointsEarned: data['pointsEarned'] ?? 0,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'deckId': deckId,
      'completedAt': Timestamp.fromDate(completedAt),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'timeSpentSeconds': timeSpent.inSeconds,
      'pointsEarned': pointsEarned,
    };
  }

  // Get completion status text
  String get statusText {
    if (accuracy >= 90) return 'Excellent!';
    if (accuracy >= 80) return 'Great!';
    if (accuracy >= 70) return 'Good!';
    if (accuracy >= 60) return 'Not bad!';
    return 'Keep trying!';
  }

  // Get completion color
  String get statusColor {
    if (accuracy >= 90) return '#4CAF50'; // Green
    if (accuracy >= 80) return '#8BC34A'; // Light Green
    if (accuracy >= 70) return '#FFC107'; // Amber
    if (accuracy >= 60) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  @override
  String toString() {
    return 'ChallengeCompletion(id: $id, deckId: $deckId, score: $score, accuracy: $accuracy)';
  }
}

