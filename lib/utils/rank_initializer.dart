import 'package:cloud_firestore/cloud_firestore.dart';

class RankInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _ranksCollection = 'ranks';

  // Initialize default ranks in Firestore
  static Future<void> initializeRanks() async {
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
        final docRef = _firestore.collection(_ranksCollection).doc();
        batch.set(docRef, rankData);
      }
      
      await batch.commit();
      print('Ranks initialized successfully!');
    } catch (e) {
      print('Error initializing ranks: $e');
    }
  }

  // Check if ranks exist
  static Future<bool> ranksExist() async {
    try {
      final snapshot = await _firestore.collection(_ranksCollection).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking ranks: $e');
      return false;
    }
  }
}

