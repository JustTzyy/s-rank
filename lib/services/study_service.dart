import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class StudyService {
  static StudyService? _instance;
  
  factory StudyService() {
    _instance ??= StudyService._internal();
    return _instance!;
  }
  
  StudyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlashcardService _flashcardService = FlashcardService();
  final String _collectionName = 'study_sessions';

  // Get reference to study sessions collection
  CollectionReference get _studySessionsCollection => 
      _firestore.collection(_collectionName);

  // Start a new study session
  Future<StudySession> startStudySession({
    required String deckId,
    required String userId,
    required StudyMode mode,
  }) async {
    try {
      // Get flashcards based on study mode
      List<Flashcard> flashcards = await _getFlashcardsForMode(deckId, mode);
      
      if (flashcards.isEmpty) {
        throw StudyException('No flashcards available for study');
      }

      // Shuffle cards for random mode
      if (mode == StudyMode.random) {
        flashcards.shuffle();
      }

      final session = StudySession(
        deckId: deckId,
        userId: userId,
        mode: mode,
        startTime: DateTime.now(),
        totalCards: flashcards.length,
        cardIds: flashcards.map((card) => card.id!).toList(),
      );

      final docRef = await _studySessionsCollection.add(session.toMap());
      return session.copyWith(id: docRef.id);
    } catch (e) {
      throw StudyException('Failed to start study session: $e');
    }
  }

  // Get flashcards based on study mode
  Future<List<Flashcard>> _getFlashcardsForMode(String deckId, StudyMode mode) async {
    final allFlashcards = await _flashcardService.getFlashcardsForDeck(deckId);
    
    if (allFlashcards.isEmpty) {
      throw StudyException('No flashcards found in this deck');
    }
    
    List<Flashcard> filteredCards;
    switch (mode) {
      case StudyMode.review:
        filteredCards = allFlashcards;
        break;
      case StudyMode.due:
        filteredCards = allFlashcards.where((card) => card.isDue).toList();
        if (filteredCards.isEmpty) {
          throw StudyException('No cards are due for review yet. Try "Review All" mode instead.');
        }
        break;
      case StudyMode.random:
        filteredCards = allFlashcards;
        break;
      case StudyMode.difficult:
        filteredCards = allFlashcards.where((card) => card.difficulty >= 4).toList();
        if (filteredCards.isEmpty) {
          throw StudyException('No difficult cards found. Try "Review All" mode instead.');
        }
        break;
    }
    
    return filteredCards;
  }

  // Submit an answer for a card
  Future<StudyResult> submitAnswer({
    required String sessionId,
    required String cardId,
    required CardRating rating,
    required bool isCorrect,
    required Duration timeSpent,
  }) async {
    try {
      final result = StudyResult(
        cardId: cardId,
        rating: rating,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
        timestamp: DateTime.now(),
      );

      // Update session with the result
      await _updateSessionWithResult(sessionId, result);

      // Update flashcard with spaced repetition data
      await _updateFlashcardWithResult(cardId, rating);

      return result;
    } catch (e) {
      throw StudyException('Failed to submit answer: $e');
    }
  }

  // Update session with study result
  Future<void> _updateSessionWithResult(String sessionId, StudyResult result) async {
    final sessionDoc = await _studySessionsCollection.doc(sessionId).get();
    if (!sessionDoc.exists) {
      throw StudyException('Study session not found');
    }

    final session = StudySession.fromFirestore(sessionDoc);
    final newCardRatings = Map<String, CardRating>.from(session.cardRatings);
    newCardRatings[result.cardId] = result.rating;

    final newStreak = result.isCorrect ? session.streak + 1 : 0;
    final newMaxStreak = newStreak > session.maxStreak ? newStreak : session.maxStreak;
    final newScore = session.score + result.points;

    await _studySessionsCollection.doc(sessionId).update({
      'completedCards': session.completedCards + 1,
      'correctAnswers': result.isCorrect 
          ? session.correctAnswers + 1 
          : session.correctAnswers,
      'incorrectAnswers': result.isCorrect 
          ? session.incorrectAnswers 
          : session.incorrectAnswers + 1,
      'score': newScore,
      'streak': newStreak,
      'maxStreak': newMaxStreak,
      'cardRatings': newCardRatings.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
    });
  }

  // Update flashcard with spaced repetition data
  Future<void> _updateFlashcardWithResult(String cardId, CardRating rating) async {
    final flashcard = await _flashcardService.getFlashcardById(cardId);
    if (flashcard == null) return;

    final now = DateTime.now();
    final newReviewCount = flashcard.reviewCount + 1;
    
    // Calculate new interval based on rating
    int newInterval = _calculateNewInterval(flashcard.interval, rating);
    double newEaseFactor = _calculateNewEaseFactor(flashcard.easeFactor, rating);

    await _flashcardService.updateFlashcardReview(
      cardId,
      difficulty: flashcard.difficulty,
      lastReviewed: now,
      reviewCount: newReviewCount,
      easeFactor: newEaseFactor,
      interval: newInterval,
    );
  }

  // Calculate new interval based on rating
  int _calculateNewInterval(int currentInterval, CardRating rating) {
    switch (rating) {
      case CardRating.again:
        return 1; // Show again tomorrow
      case CardRating.hard:
        return (currentInterval * 1.2).round().clamp(1, 6);
      case CardRating.good:
        return (currentInterval * 1.3).round().clamp(1, 10);
      case CardRating.easy:
        return (currentInterval * 1.4).round().clamp(4, 30);
    }
  }

  // Calculate new ease factor based on rating
  double _calculateNewEaseFactor(double currentEaseFactor, CardRating rating) {
    double newEaseFactor = currentEaseFactor;
    
    switch (rating) {
      case CardRating.again:
        newEaseFactor = (currentEaseFactor - 0.2).clamp(1.3, 2.5);
        break;
      case CardRating.hard:
        newEaseFactor = (currentEaseFactor - 0.15).clamp(1.3, 2.5);
        break;
      case CardRating.good:
        // No change for good rating
        break;
      case CardRating.easy:
        newEaseFactor = (currentEaseFactor + 0.15).clamp(1.3, 2.5);
        break;
    }
    
    return newEaseFactor;
  }

  // Complete a study session
  Future<StudySession> completeStudySession(String sessionId) async {
    try {
      final now = DateTime.now();
      await _studySessionsCollection.doc(sessionId).update({
        'endTime': Timestamp.fromDate(now),
        'isCompleted': true,
      });

      final sessionDoc = await _studySessionsCollection.doc(sessionId).get();
      return StudySession.fromFirestore(sessionDoc);
    } catch (e) {
      throw StudyException('Failed to complete study session: $e');
    }
  }

  // Get study session by ID
  Future<StudySession?> getStudySession(String sessionId) async {
    try {
      final doc = await _studySessionsCollection.doc(sessionId).get();
      if (doc.exists) {
        return StudySession.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw StudyException('Failed to get study session: $e');
    }
  }

  // Get study sessions for a user
  Future<List<StudySession>> getUserStudySessions(String userId) async {
    try {
      final snapshot = await _studySessionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => StudySession.fromFirestore(doc)).toList();
    } catch (e) {
      throw StudyException('Failed to get user study sessions: $e');
    }
  }

  // Get study sessions for a deck
  Future<List<StudySession>> getDeckStudySessions(String deckId) async {
    try {
      final snapshot = await _studySessionsCollection
          .where('deckId', isEqualTo: deckId)
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => StudySession.fromFirestore(doc)).toList();
    } catch (e) {
      throw StudyException('Failed to get deck study sessions: $e');
    }
  }

  // Get study statistics for a user
  Future<Map<String, dynamic>> getUserStudyStats(String userId) async {
    try {
      final sessions = await getUserStudySessions(userId);
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      
      if (completedSessions.isEmpty) {
        return {
          'totalSessions': 0,
          'totalCards': 0,
          'totalScore': 0,
          'averageAccuracy': 0.0,
          'bestStreak': 0,
          'totalStudyTime': 0,
        };
      }

      final totalCards = completedSessions.fold(0, (sum, session) => sum + session.completedCards);
      final totalScore = completedSessions.fold(0.0, (sum, session) => sum + session.score);
      final totalAccuracy = completedSessions.fold(0.0, (sum, session) => sum + session.accuracy);
      final bestStreak = completedSessions.fold(0, (max, session) => 
          session.maxStreak > max ? session.maxStreak : max);
      
      final totalStudyTime = completedSessions.fold(0, (sum, session) {
        if (session.endTime != null) {
          return sum + session.endTime!.difference(session.startTime).inMinutes;
        }
        return sum;
      });

      return {
        'totalSessions': completedSessions.length,
        'totalCards': totalCards,
        'totalScore': totalScore,
        'averageAccuracy': totalAccuracy / completedSessions.length,
        'bestStreak': bestStreak,
        'totalStudyTime': totalStudyTime,
      };
    } catch (e) {
      throw StudyException('Failed to get study statistics: $e');
    }
  }
}

// Custom exception class for study operations
class StudyException implements Exception {
  final String message;
  StudyException(this.message);

  @override
  String toString() => 'StudyException: $message';
}

