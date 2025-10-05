import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/global_user_rank.dart';
import 'course_service.dart';
import 'deck_service.dart';
import 'flashcard_service.dart';
import 'rank_service.dart';

class GlobalRankService {
  static GlobalRankService? _instance;
  
  factory GlobalRankService() {
    _instance ??= GlobalRankService._internal();
    return _instance!;
  }
  
  GlobalRankService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'globalUserRanks';

  // Get reference to globalUserRanks collection
  CollectionReference get _globalUserRanksCollection => 
      _firestore.collection(_collectionName);

  // Update or create global user rank
  Future<void> updateGlobalUserRank(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get user's courses
      final courseService = CourseService();
      final userCourses = await courseService.getCoursesForUser(userId);
      
      int totalPoints = 0;
      int totalCourses = userCourses.length;
      int totalDecks = 0;
      int totalFlashcards = 0;
      int studiedCards = 0;
      double totalAccuracy = 0.0;
      int coursesWithData = 0;

      // Calculate totals across all courses
      for (final course in userCourses) {
        try {
          // Get user rank for this course
          final rankService = RankService();
          final userRank = await rankService.getUserRank(userId, course.id!);
          
          if (userRank != null) {
            totalPoints += userRank.totalPoints;
            studiedCards += userRank.totalQuestions;
            totalAccuracy += userRank.accuracy;
            coursesWithData++;
          }

          // Get decks for this course
          final deckService = DeckService();
          final courseDecks = await deckService.getDecksForCourse(course.id!);
          totalDecks += courseDecks.length;

          // Get flashcards for all decks
          final flashcardService = FlashcardService();
          for (final deck in courseDecks) {
            final deckFlashcards = await flashcardService.getFlashcardsForDeck(deck.id!);
            totalFlashcards += deckFlashcards.length;
          }
        } catch (e) {
          // Continue with other courses if one fails
          continue;
        }
      }

      // Calculate average accuracy
      final averageAccuracy = coursesWithData > 0 ? totalAccuracy / coursesWithData : 0.0;

      // Determine rank based on total points using database ranking system
      final rank = await _determineRank(totalPoints);

      // Create or update global user rank
      final globalUserRank = GlobalUserRank(
        id: userId,
        userId: userId,
        displayName: user.displayName ?? 'Anonymous',
        email: user.email ?? '',
        totalPoints: totalPoints,
        rank: rank,
        lastUpdated: DateTime.now(),
        totalCourses: totalCourses,
        totalDecks: totalDecks,
        totalFlashcards: totalFlashcards,
        studiedCards: studiedCards,
        accuracy: averageAccuracy,
      );

      await _globalUserRanksCollection.doc(userId).set(globalUserRank.toMap());
    } catch (e) {
      throw GlobalRankException('Failed to update global user rank: $e');
    }
  }

  // Get global user rank
  Future<GlobalUserRank?> getGlobalUserRank(String userId) async {
    try {
      final doc = await _globalUserRanksCollection.doc(userId).get();
      if (doc.exists) {
        return GlobalUserRank.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw GlobalRankException('Failed to get global user rank: $e');
    }
  }

  // Determine rank based on points using the database ranking system
  Future<String> _determineRank(int points) async {
    try {
      final rankService = RankService();
      final rank = await rankService.getRankForPoints(points);
      return rank?.name ?? 'C-Rank'; // Default to C-Rank if no rank found
    } catch (e) {
      print('Error determining rank: $e');
      return 'C-Rank'; // Fallback to C-Rank
    }
  }

  // Update all users' global ranks (admin function)
  Future<void> updateAllGlobalRanks() async {
    try {
      // Get all users from userRanks collection
      final userRanksSnapshot = await _firestore.collection('userRanks').get();
      final userIds = userRanksSnapshot.docs.map((doc) => doc.id).toSet();
      
      for (final userId in userIds) {
        await updateGlobalUserRank(userId);
      }
    } catch (e) {
      throw GlobalRankException('Failed to update all global ranks: $e');
    }
  }

  // Stream of global user rank for current user
  Stream<GlobalUserRank?> getCurrentUserGlobalRankStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    
    return _globalUserRanksCollection.doc(user.uid).snapshots().map((doc) {
      if (doc.exists) {
        return GlobalUserRank.fromFirestore(doc);
      }
      return null;
    });
  }
}

// Custom exception class for global rank operations
class GlobalRankException implements Exception {
  final String message;
  GlobalRankException(this.message);

  @override
  String toString() => 'GlobalRankException: $message';
}
