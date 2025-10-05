import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalUserRank {
  final String? id;
  final String userId;
  final String displayName;
  final String email;
  final int totalPoints;
  final String rank; // S, A, B, C, D, F
  final DateTime lastUpdated;
  final int totalCourses;
  final int totalDecks;
  final int totalFlashcards;
  final int studiedCards;
  final double accuracy;

  GlobalUserRank({
    this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.totalPoints,
    required this.rank,
    required this.lastUpdated,
    this.totalCourses = 0,
    this.totalDecks = 0,
    this.totalFlashcards = 0,
    this.studiedCards = 0,
    this.accuracy = 0.0,
  });

  // Factory constructor from Firestore
  factory GlobalUserRank.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GlobalUserRank(
      id: doc.id,
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      rank: data['rank'] ?? 'F',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCourses: data['totalCourses'] ?? 0,
      totalDecks: data['totalDecks'] ?? 0,
      totalFlashcards: data['totalFlashcards'] ?? 0,
      studiedCards: data['studiedCards'] ?? 0,
      accuracy: (data['accuracy'] ?? 0.0).toDouble(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'totalPoints': totalPoints,
      'rank': rank,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'totalCourses': totalCourses,
      'totalDecks': totalDecks,
      'totalFlashcards': totalFlashcards,
      'studiedCards': studiedCards,
      'accuracy': accuracy,
    };
  }

  // Copy with method
  GlobalUserRank copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? email,
    int? totalPoints,
    String? rank,
    DateTime? lastUpdated,
    int? totalCourses,
    int? totalDecks,
    int? totalFlashcards,
    int? studiedCards,
    double? accuracy,
  }) {
    return GlobalUserRank(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      totalPoints: totalPoints ?? this.totalPoints,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalCourses: totalCourses ?? this.totalCourses,
      totalDecks: totalDecks ?? this.totalDecks,
      totalFlashcards: totalFlashcards ?? this.totalFlashcards,
      studiedCards: studiedCards ?? this.studiedCards,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  String toString() {
    return 'GlobalUserRank(id: $id, userId: $userId, displayName: $displayName, totalPoints: $totalPoints, rank: $rank)';
  }
}
