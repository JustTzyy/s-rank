import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_completion.dart';

class ChallengeCompletionService {
  static ChallengeCompletionService? _instance;
  
  factory ChallengeCompletionService() {
    _instance ??= ChallengeCompletionService._internal();
    return _instance!;
  }
  
  ChallengeCompletionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _completionsCollection = 'challenge_completions';

  // Get reference to completions collection
  CollectionReference get _completionsCollectionRef => 
      _firestore.collection(_completionsCollection);

  // Save challenge completion
  Future<String> saveCompletion(ChallengeCompletion completion) async {
    try {
      final docRef = await _completionsCollectionRef.add(completion.toMap());
      return docRef.id;
    } catch (e) {
      throw ChallengeCompletionException('Failed to save completion: $e');
    }
  }

  // Get completion for a specific deck by user
  Future<ChallengeCompletion?> getCompletion(String userId, String courseId, String deckId) async {
    try {
      final snapshot = await _completionsCollectionRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .where('deckId', isEqualTo: deckId)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Sort in memory and get the most recent completion
        final completions = snapshot.docs.map((doc) => ChallengeCompletion.fromFirestore(doc)).toList();
        completions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return completions.first;
      }
      return null;
    } catch (e) {
      throw ChallengeCompletionException('Failed to get completion: $e');
    }
  }

  // Get all completions for a user in a course
  Future<List<ChallengeCompletion>> getUserCompletions(String userId, String courseId) async {
    try {
      final snapshot = await _completionsCollectionRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      final completions = snapshot.docs.map((doc) => ChallengeCompletion.fromFirestore(doc)).toList();
      completions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      return completions;
    } catch (e) {
      throw ChallengeCompletionException('Failed to get user completions: $e');
    }
  }

  // Check if deck is completed by user
  Future<bool> isDeckCompleted(String userId, String courseId, String deckId) async {
    try {
      final completion = await getCompletion(userId, courseId, deckId);
      return completion != null;
    } catch (e) {
      return false;
    }
  }

  // Get completion statistics for a deck
  Future<Map<String, dynamic>> getDeckStats(String deckId) async {
    try {
      final snapshot = await _completionsCollectionRef
          .where('deckId', isEqualTo: deckId)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {
          'totalCompletions': 0,
          'averageScore': 0.0,
          'averageAccuracy': 0.0,
          'bestScore': 0,
          'bestAccuracy': 0.0,
        };
      }

      final completions = snapshot.docs.map((doc) => ChallengeCompletion.fromFirestore(doc)).toList();
      
      final totalCompletions = completions.length;
      final totalScore = completions.fold(0, (sum, completion) => sum + completion.score);
      final totalAccuracy = completions.fold(0.0, (sum, completion) => sum + completion.accuracy);
      final bestScore = completions.fold(0, (max, completion) => completion.score > max ? completion.score : max);
      final bestAccuracy = completions.fold(0.0, (max, completion) => completion.accuracy > max ? completion.accuracy : max);

      return {
        'totalCompletions': totalCompletions,
        'averageScore': totalScore / totalCompletions,
        'averageAccuracy': totalAccuracy / totalCompletions,
        'bestScore': bestScore,
        'bestAccuracy': bestAccuracy,
      };
    } catch (e) {
      throw ChallengeCompletionException('Failed to get deck stats: $e');
    }
  }

  // Delete completion (for retry)
  Future<void> deleteCompletion(String completionId) async {
    try {
      await _completionsCollectionRef.doc(completionId).delete();
    } catch (e) {
      throw ChallengeCompletionException('Failed to delete completion: $e');
    }
  }
}

// Custom exception class for challenge completion operations
class ChallengeCompletionException implements Exception {
  final String message;
  ChallengeCompletionException(this.message);

  @override
  String toString() => 'ChallengeCompletionException: $message';
}
