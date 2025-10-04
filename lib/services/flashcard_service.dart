import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard.dart';

class FlashcardService {
  static final FlashcardService _instance = FlashcardService._internal();
  factory FlashcardService() => _instance;
  FlashcardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'flashcards';

  // Get reference to flashcards collection
  CollectionReference get _flashcardsCollection => 
      _firestore.collection(_collectionName);

  // Stream of flashcards for a specific deck
  Stream<List<Flashcard>> getFlashcardsStreamForDeck(String deckId) {
    return _flashcardsCollection
        .where('deckId', isEqualTo: deckId)
        .snapshots()
        .map((snapshot) {
      final flashcards = snapshot.docs.map((doc) => Flashcard.fromFirestore(doc)).toList();
      // Sort in memory instead of using orderBy to avoid index requirement
      flashcards.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return flashcards;
    });
  }

  // Get all flashcards for a specific deck
  Future<List<Flashcard>> getFlashcardsForDeck(String deckId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .get();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      final flashcards = snapshot.docs.map((doc) => Flashcard.fromFirestore(doc)).toList();
      flashcards.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return flashcards;
    } catch (e) {
      throw FlashcardException('Failed to fetch flashcards: $e');
    }
  }

  // Get flashcards due for review
  Future<List<Flashcard>> getDueFlashcards(String deckId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .get();
      
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => Flashcard.fromFirestore(doc))
          .where((card) {
            if (card.lastReviewed == null) return true;
            final daysSinceReview = now.difference(card.lastReviewed!).inDays;
            return daysSinceReview >= card.interval;
          })
          .toList();
    } catch (e) {
      throw FlashcardException('Failed to fetch due flashcards: $e');
    }
  }

  // Get a specific flashcard by ID
  Future<Flashcard?> getFlashcardById(String id) async {
    try {
      final doc = await _flashcardsCollection.doc(id).get();
      if (doc.exists) {
        return Flashcard.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw FlashcardException('Failed to fetch flashcard: $e');
    }
  }

  // Add a new flashcard
  Future<String> addFlashcard(Flashcard flashcard) async {
    try {
      final docRef = await _flashcardsCollection.add(flashcard.toMap());
      return docRef.id;
    } catch (e) {
      throw FlashcardException('Failed to add flashcard: $e');
    }
  }

  // Update an existing flashcard
  Future<void> updateFlashcard(String id, Flashcard flashcard) async {
    try {
      final updateData = {
        'front': flashcard.front,
        'back': flashcard.back,
        'difficulty': flashcard.difficulty,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _flashcardsCollection.doc(id).update(updateData);
    } catch (e) {
      throw FlashcardException('Failed to update flashcard: $e');
    }
  }

  // Delete a flashcard
  Future<void> deleteFlashcard(String id) async {
    try {
      await _flashcardsCollection.doc(id).delete();
    } catch (e) {
      throw FlashcardException('Failed to delete flashcard: $e');
    }
  }

  // Search flashcards by front or back text within a deck
  Future<List<Flashcard>> searchFlashcardsInDeck(String deckId, String query) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .get();
      return snapshot.docs
          .map((doc) => Flashcard.fromFirestore(doc))
          .where((card) => 
              card.front.toLowerCase().contains(query.toLowerCase()) ||
              card.back.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw FlashcardException('Failed to search flashcards: $e');
    }
  }

  // Update flashcard review data (for spaced repetition)
  Future<void> updateFlashcardReview(String id, {
    required int difficulty,
    required DateTime lastReviewed,
    required int reviewCount,
    required double easeFactor,
    required int interval,
  }) async {
    try {
      await _flashcardsCollection.doc(id).update({
        'difficulty': difficulty,
        'lastReviewed': Timestamp.fromDate(lastReviewed),
        'reviewCount': reviewCount,
        'easeFactor': easeFactor,
        'interval': interval,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FlashcardException('Failed to update flashcard review: $e');
    }
  }

  // Get flashcard count for a deck
  Future<int> getFlashcardCountForDeck(String deckId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw FlashcardException('Failed to get flashcard count: $e');
    }
  }

  // Get studied flashcard count for a deck
  Future<int> getStudiedFlashcardCountForDeck(String deckId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .where('reviewCount', isGreaterThan: 0)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw FlashcardException('Failed to get studied flashcard count: $e');
    }
  }

  // Get flashcards by difficulty
  Future<List<Flashcard>> getFlashcardsByDifficulty(String deckId, int difficulty) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .where('difficulty', isEqualTo: difficulty)
          .get();
      return snapshot.docs.map((doc) => Flashcard.fromFirestore(doc)).toList();
    } catch (e) {
      throw FlashcardException('Failed to fetch flashcards by difficulty: $e');
    }
  }

  // Batch add flashcards
  Future<List<String>> addMultipleFlashcards(List<Flashcard> flashcards) async {
    try {
      final batch = _firestore.batch();
      final docRefs = <DocumentReference>[];
      
      for (final flashcard in flashcards) {
        final docRef = _flashcardsCollection.doc();
        batch.set(docRef, flashcard.toMap());
        docRefs.add(docRef);
      }
      
      await batch.commit();
      return docRefs.map((ref) => ref.id).toList();
    } catch (e) {
      throw FlashcardException('Failed to add multiple flashcards: $e');
    }
  }

  // Delete all flashcards in a deck
  Future<void> deleteAllFlashcardsInDeck(String deckId) async {
    try {
      final snapshot = await _flashcardsCollection
          .where('deckId', isEqualTo: deckId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw FlashcardException('Failed to delete all flashcards in deck: $e');
    }
  }
}

// Custom exception class for flashcard operations
class FlashcardException implements Exception {
  final String message;
  FlashcardException(this.message);

  @override
  String toString() => 'FlashcardException: $message';
}
