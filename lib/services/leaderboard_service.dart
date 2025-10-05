import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/global_user_rank.dart';

class LeaderboardService {
  static LeaderboardService? _instance;
  
  factory LeaderboardService() {
    _instance ??= LeaderboardService._internal();
    return _instance!;
  }
  
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'globalUserRanks';

  // Get reference to userRanks collection
  CollectionReference get _userRanksCollection => 
      _firestore.collection(_collectionName);

  // Get top 100 users by points (leaderboard)
  Future<List<GlobalUserRank>> getTopUsers({int limit = 100}) async {
    try {
      final snapshot = await _userRanksCollection
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => GlobalUserRank.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw LeaderboardException('Failed to fetch leaderboard: $e');
    }
  }

  // Stream of top 100 users (for real-time updates)
  Stream<List<GlobalUserRank>> getTopUsersStream({int limit = 100}) {
    return _userRanksCollection
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GlobalUserRank.fromFirestore(doc))
          .toList();
    });
  }

  // Get user's rank position
  Future<int> getUserRankPosition(String userId) async {
    try {
      final userDoc = await _userRanksCollection.doc(userId).get();
      if (!userDoc.exists) return -1;
      
      final userPoints = (userDoc.data() as Map<String, dynamic>?)?['totalPoints'] as int? ?? 0;
      
      final higherUsersSnapshot = await _userRanksCollection
          .where('totalPoints', isGreaterThan: userPoints)
          .get();
      
      return higherUsersSnapshot.docs.length + 1;
    } catch (e) {
      throw LeaderboardException('Failed to get user rank position: $e');
    }
  }

  // Get users around current user's rank (for context)
  Future<List<GlobalUserRank>> getUsersAroundRank(String userId, {int range = 5}) async {
    try {
      final userRank = await getUserRankPosition(userId);
      if (userRank == -1) return [];
      
      // Calculate rank range for context (not used in current implementation)
      // final startRank = (userRank - range).clamp(1, 1000);
      // final endRank = userRank + range;
      
      // Get users with points in a range around the user's points
      final userDoc = await _userRanksCollection.doc(userId).get();
      if (!userDoc.exists) return [];
      
      final userPoints = (userDoc.data() as Map<String, dynamic>?)?['totalPoints'] as int? ?? 0;
      final pointRange = 100; // Points range to search
      
      final snapshot = await _userRanksCollection
          .where('totalPoints', isGreaterThanOrEqualTo: userPoints - pointRange)
          .where('totalPoints', isLessThanOrEqualTo: userPoints + pointRange)
          .orderBy('totalPoints', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => GlobalUserRank.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw LeaderboardException('Failed to get users around rank: $e');
    }
  }

  // Get leaderboard statistics
  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final totalUsersSnapshot = await _userRanksCollection.get();
      final totalUsers = totalUsersSnapshot.docs.length;
      
      if (totalUsers == 0) {
        return {
          'totalUsers': 0,
          'averagePoints': 0,
          'highestPoints': 0,
        };
      }
      
      int totalPoints = 0;
      int highestPoints = 0;
      
      for (final doc in totalUsersSnapshot.docs) {
        final points = (doc.data() as Map<String, dynamic>)['totalPoints'] as int? ?? 0;
        totalPoints += points;
        if (points > highestPoints) {
          highestPoints = points;
        }
      }
      
      return {
        'totalUsers': totalUsers,
        'averagePoints': totalPoints ~/ totalUsers,
        'highestPoints': highestPoints,
      };
    } catch (e) {
      throw LeaderboardException('Failed to get leaderboard stats: $e');
    }
  }
}

// Custom exception class for leaderboard operations
class LeaderboardException implements Exception {
  final String message;
  LeaderboardException(this.message);

  @override
  String toString() => 'LeaderboardException: $message';
}
