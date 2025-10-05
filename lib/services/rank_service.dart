import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rank.dart';

class RankService {
  static RankService? _instance;
  
  factory RankService() {
    _instance ??= RankService._internal();
    return _instance!;
  }
  
  RankService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ranksCollection = 'ranks';
  final String _userRanksCollection = 'user_ranks';

  // Get reference to ranks collection
  CollectionReference get _ranksCollectionRef => 
      _firestore.collection(_ranksCollection);

  // Get reference to user ranks collection
  CollectionReference get _userRanksCollectionRef => 
      _firestore.collection(_userRanksCollection);

  // Get all ranks
  Future<List<Rank>> getAllRanks() async {
    try {
      final snapshot = await _ranksCollectionRef
          .orderBy('order', descending: false)
          .get();
      
      return snapshot.docs.map((doc) => Rank.fromFirestore(doc)).toList();
    } catch (e) {
      throw RankException('Failed to get ranks: $e');
    }
  }

  // Get rank by ID
  Future<Rank?> getRankById(String rankId) async {
    try {
      final doc = await _ranksCollectionRef.doc(rankId).get();
      if (doc.exists) {
        return Rank.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw RankException('Failed to get rank: $e');
    }
  }

  // Get rank for a specific point value
  Future<Rank?> getRankForPoints(int points) async {
    try {
      final ranks = await getAllRanks();
      
      if (ranks.isEmpty) {
        // If no ranks exist, initialize them
        await _initializeDefaultRanks();
        final newRanks = await getAllRanks();
        if (newRanks.isEmpty) {
          throw RankException('No ranks available and failed to initialize');
        }
        ranks.addAll(newRanks);
      }
      
      // Find the rank that contains this point value
      for (final rank in ranks) {
        if (rank.isPointInRange(points)) {
          return rank;
        }
      }
      
      // If no rank found, return the lowest rank (should be C-Rank with 0 points)
      final lowestRank = ranks.isNotEmpty ? ranks.first : null;
      if (lowestRank == null) {
        throw RankException('No ranks available for points: $points');
      }
      return lowestRank;
    } catch (e) {
      throw RankException('Failed to get rank for points: $e');
    }
  }

  // Initialize default ranks if they don't exist
  Future<void> _initializeDefaultRanks() async {
    try {
      final ranks = [
        {
          'name': 'C-Rank',
          'minPoints': 0,
          'maxPoints': 199,
          'description': 'Beginner level - Keep learning!',
          'order': 1,
        },
        {
          'name': 'B-Rank',
          'minPoints': 200,
          'maxPoints': 499,
          'description': 'Intermediate level - You\'re getting better!',
          'order': 2,
        },
        {
          'name': 'A-Rank',
          'minPoints': 500,
          'maxPoints': 999,
          'description': 'Advanced level - Great job!',
          'order': 3,
        },
        {
          'name': 'S-Rank',
          'minPoints': 1000,
          'maxPoints': 99999,
          'description': 'Expert level - You\'re a master!',
          'order': 4,
        },
      ];

      final batch = _firestore.batch();
      
      for (final rankData in ranks) {
        final docRef = _ranksCollectionRef.doc();
        batch.set(docRef, rankData);
      }
      
      await batch.commit();
      print('Default ranks initialized successfully!');
    } catch (e) {
      print('Error initializing default ranks: $e');
      throw RankException('Failed to initialize default ranks: $e');
    }
  }

  // Get user's current rank for a course
  Future<UserRank?> getUserRank(String userId, String courseId) async {
    try {
      final snapshot = await _userRanksCollectionRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return UserRank.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw RankException('Failed to get user rank: $e');
    }
  }

  // Update user's points and rank
  Future<UserRank> updateUserPoints({
    required String userId,
    required String courseId,
    required int pointsEarned,
    required bool isCorrect,
  }) async {
    try {
      // Get current user rank
      UserRank? currentUserRank = await getUserRank(userId, courseId);
      
      // Calculate new totals
      final newTotalPoints = (currentUserRank?.totalPoints ?? 0) + pointsEarned;
      final newCorrectAnswers = (currentUserRank?.correctAnswers ?? 0) + (isCorrect ? 1 : 0);
      final newTotalQuestions = (currentUserRank?.totalQuestions ?? 0) + 1;
      final newAccuracy = newTotalQuestions > 0 ? (newCorrectAnswers / newTotalQuestions) * 100 : 0.0;
      
      // Get the new rank based on total points
      final newRank = await getRankForPoints(newTotalPoints);
      if (newRank == null) {
        throw RankException('No rank found for points: $newTotalPoints');
      }
      
      // Create or update user rank
      final userRank = UserRank(
        id: currentUserRank?.id,
        userId: userId,
        courseId: courseId,
        totalPoints: newTotalPoints,
        currentRankId: newRank.id!,
        lastUpdated: DateTime.now(),
        correctAnswers: newCorrectAnswers,
        totalQuestions: newTotalQuestions,
        accuracy: newAccuracy,
      );
      
      if (currentUserRank?.id != null) {
        // Update existing rank
        await _userRanksCollectionRef.doc(currentUserRank!.id!).update(userRank.toMap());
      } else {
        // Create new rank
        final docRef = await _userRanksCollectionRef.add(userRank.toMap());
        return userRank.copyWith(id: docRef.id);
      }
      
      return userRank;
    } catch (e) {
      throw RankException('Failed to update user points: $e');
    }
  }

  // Get leaderboard for a course
  Future<List<UserRank>> getCourseLeaderboard(String courseId, {int limit = 10}) async {
    try {
      final snapshot = await _userRanksCollectionRef
          .where('courseId', isEqualTo: courseId)
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => UserRank.fromFirestore(doc)).toList();
    } catch (e) {
      throw RankException('Failed to get leaderboard: $e');
    }
  }

  // Get user's rank position in course
  Future<int> getUserRankPosition(String userId, String courseId) async {
    try {
      final userRank = await getUserRank(userId, courseId);
      if (userRank == null) return -1;
      
      final snapshot = await _userRanksCollectionRef
          .where('courseId', isEqualTo: courseId)
          .where('totalPoints', isGreaterThan: userRank.totalPoints)
          .get();
      
      return snapshot.docs.length + 1;
    } catch (e) {
      throw RankException('Failed to get user rank position: $e');
    }
  }

  // Calculate points for a question based on difficulty and time
  int calculatePoints({
    required int difficulty,
    required bool isCorrect,
    required Duration timeSpent,
    required int basePoints,
  }) {
    if (!isCorrect) return 0;
    
    // Simple points based on difficulty only
    // Easy = 1, Medium = 2, Hard = 3, Very Hard = 4, Expert = 5
    switch (difficulty) {
      case 1: // Easy
        return 1;
      case 2: // Medium
        return 2;
      case 3: // Hard
        return 3;
      case 4: // Very Hard
        return 4;
      case 5: // Expert
        return 5;
      default:
        return 1; // Default to easy points
    }
  }
}

// Custom exception class for rank operations
class RankException implements Exception {
  final String message;
  RankException(this.message);

  @override
  String toString() => 'RankException: $message';
}
