import 'package:cloud_firestore/cloud_firestore.dart';

class Rank {
  final String? id;
  final String name;
  final int minPoints;
  final int maxPoints;
  final String? description;
  final String? iconUrl;
  final int order; // For sorting ranks (1 = lowest, higher = better)

  Rank({
    this.id,
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    this.description,
    this.iconUrl,
    required this.order,
  });

  // Factory constructor from Firestore
  factory Rank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rank(
      id: doc.id,
      name: data['name'] ?? '',
      minPoints: data['minPoints'] ?? 0,
      maxPoints: data['maxPoints'] ?? 0,
      description: data['description'],
      iconUrl: data['iconUrl'],
      order: data['order'] ?? 0,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'description': description,
      'iconUrl': iconUrl,
      'order': order,
    };
  }

  // Check if a point value falls within this rank's range
  bool isPointInRange(int points) {
    return points >= minPoints && points <= maxPoints;
  }

  // Get rank color based on order
  String get color {
    switch (order) {
      case 1:
        return '#FF6B6B'; // Red
      case 2:
        return '#4ECDC4'; // Teal
      case 3:
        return '#45B7D1'; // Blue
      case 4:
        return '#96CEB4'; // Green
      case 5:
        return '#FFEAA7'; // Yellow
      case 6:
        return '#DDA0DD'; // Plum
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get rank icon
  String get icon {
    switch (order) {
      case 1:
        return '🥉'; // Bronze
      case 2:
        return '🥈'; // Silver
      case 3:
        return '🥇'; // Gold
      case 4:
        return '💎'; // Diamond
      case 5:
        return '👑'; // Crown
      case 6:
        return '🌟'; // Star
      default:
        return '⭐'; // Star
    }
  }

  @override
  String toString() {
    return 'Rank(id: $id, name: $name, minPoints: $minPoints, maxPoints: $maxPoints, order: $order)';
  }
}

class UserRank {
  final String? id;
  final String userId;
  final String courseId;
  final int totalPoints;
  final String currentRankId;
  final DateTime lastUpdated;
  final int correctAnswers;
  final int totalQuestions;
  final double accuracy;

  UserRank({
    this.id,
    required this.userId,
    required this.courseId,
    required this.totalPoints,
    required this.currentRankId,
    required this.lastUpdated,
    required this.correctAnswers,
    required this.totalQuestions,
    this.accuracy = 0.0,
  });

  // Factory constructor from Firestore
  factory UserRank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRank(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      currentRankId: data['currentRankId'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      correctAnswers: data['correctAnswers'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'totalPoints': totalPoints,
      'currentRankId': currentRankId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'accuracy': accuracy,
    };
  }

  // Calculate accuracy percentage
  double get accuracyPercentage {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  // Copy with method
  UserRank copyWith({
    String? id,
    String? userId,
    String? courseId,
    int? totalPoints,
    String? currentRankId,
    DateTime? lastUpdated,
    int? correctAnswers,
    int? totalQuestions,
    double? accuracy,
  }) {
    return UserRank(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentRankId: currentRankId ?? this.currentRankId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  String toString() {
    return 'UserRank(id: $id, userId: $userId, courseId: $courseId, totalPoints: $totalPoints, currentRankId: $currentRankId)';
  }
}
