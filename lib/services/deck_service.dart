import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';
import 'flashcard_service.dart';

class DeckService {
  static DeckService? _instance;
  
  factory DeckService() {
    _instance ??= DeckService._internal();
    return _instance!;
  }
  
  DeckService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'decks';

  // Get reference to decks collection
  CollectionReference get _decksCollection => 
      _firestore.collection(_collectionName);

  // Stream of decks for a specific course
  Stream<List<Deck>> getDecksStreamForCourse(String courseId) {
    return _decksCollection
        .where('courseId', isEqualTo: courseId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final decks = snapshot.docs.map((doc) => Deck.fromFirestore(doc)).toList();
      // Sort in memory instead of using orderBy to avoid index requirement
      decks.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return decks;
    });
  }

  // Get all decks for a specific course
  Future<List<Deck>> getDecksForCourse(String courseId) async {
    try {
      final snapshot = await _decksCollection
          .where('courseId', isEqualTo: courseId)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      // Sort in memory instead of using orderBy to avoid index requirement
      final decks = snapshot.docs
          .map((doc) => Deck.fromFirestore(doc))
          .where((deck) => deck.deletedAt == null) // Filter out archived decks
          .toList();
      decks.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      return decks;
    } catch (e) {
      throw DeckException('Failed to fetch decks: $e');
    }
  }

  // Get a specific deck by ID
  Future<Deck?> getDeckById(String id) async {
    try {
      final doc = await _decksCollection.doc(id).get();
      if (doc.exists) {
        return Deck.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw DeckException('Failed to fetch deck: $e');
    }
  }

  // Add a new deck
  Future<String> addDeck(Deck deck) async {
    try {
      final docRef = await _decksCollection.add(deck.toMap());
      return docRef.id;
    } catch (e) {
      throw DeckException('Failed to add deck: $e');
    }
  }

  // Update an existing deck
  Future<void> updateDeck(String id, Deck deck) async {
    try {
      final updateData = {
        'title': deck.title,
        'description': deck.description,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _decksCollection.doc(id).update(updateData);
    } catch (e) {
      throw DeckException('Failed to update deck: $e');
    }
  }

  // Soft delete a deck
  Future<void> deleteDeck(String id) async {
    try {
      await _decksCollection.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DeckException('Failed to delete deck: $e');
    }
  }

  // Search decks by title within a course
  Future<List<Deck>> searchDecksInCourse(String courseId, String query) async {
    try {
      final snapshot = await _decksCollection
          .where('courseId', isEqualTo: courseId)
          .where('isDeleted', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => Deck.fromFirestore(doc))
          .where((deck) => deck.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw DeckException('Failed to search decks: $e');
    }
  }

  // Update deck statistics (total cards, studied cards)
  Future<void> updateDeckStats(String deckId, {int? totalCards, int? studiedCards}) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (totalCards != null) {
        updateData['totalCards'] = totalCards;
      }
      
      if (studiedCards != null) {
        updateData['studiedCards'] = studiedCards;
      }
      
      await _decksCollection.doc(deckId).update(updateData);
    } catch (e) {
      throw DeckException('Failed to update deck stats: $e');
    }
  }

  // Update last studied timestamp
  Future<void> updateLastStudied(String deckId) async {
    try {
      await _decksCollection.doc(deckId).update({
        'lastStudied': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DeckException('Failed to update last studied: $e');
    }
  }

  // Get deck count for a course
  Future<int> getDeckCountForCourse(String courseId) async {
    try {
      final snapshot = await _decksCollection
          .where('courseId', isEqualTo: courseId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw DeckException('Failed to get deck count: $e');
    }
  }

  // Get all decks (admin function)
  Future<List<Deck>> getAllDecks() async {
    try {
      final snapshot = await _decksCollection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => Deck.fromFirestore(doc)).toList();
    } catch (e) {
      throw DeckException('Failed to fetch all decks: $e');
    }
  }

  // Archive deck (soft delete) - cascades to flashcards
  Future<void> archiveDeck(String deckId) async {
    try {
      // First, archive all flashcards in this deck
      final FlashcardService flashcardService = FlashcardService();
      await flashcardService.archiveAllFlashcardsInDeck(deckId);
      
      // Then archive the deck
      await _decksCollection.doc(deckId).update({
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw DeckException('Failed to archive deck: $e');
    }
  }

  // Restore deck from archive - only restores the deck itself
  Future<void> restoreDeck(String deckId) async {
    try {
      // Only restore the deck, not the flashcards
      await _decksCollection.doc(deckId).update({
        'deletedAt': FieldValue.delete(),
      });
    } catch (e) {
      throw DeckException('Failed to restore deck: $e');
    }
  }

  // Get archived decks by course ID
  Future<List<Deck>> getArchivedDecksByCourseId(String courseId) async {
    try {
      final snapshot = await _decksCollection
          .where('courseId', isEqualTo: courseId)
          .where('deletedAt', isNull: false) // Only get archived decks
          .get();
      
      return snapshot.docs
          .map((doc) => Deck.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw DeckException('Failed to fetch archived decks: $e');
    }
  }

  // Delete deck forever (hard delete)
  Future<void> deleteDeckForever(String deckId) async {
    try {
      await _decksCollection.doc(deckId).delete();
    } catch (e) {
      throw DeckException('Failed to delete deck forever: $e');
    }
  }
}

// Custom exception class for deck operations
class DeckException implements Exception {
  final String message;
  DeckException(this.message);

  @override
  String toString() => 'DeckException: $message';
}
