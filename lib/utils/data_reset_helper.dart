import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataResetHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reset all progress data for current user
  static Future<void> resetAllProgressData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Starting data reset for user: ${user.uid}');

      // Reset daily progress
      await _resetDailyProgress(user.uid);
      
      // Reset weekly progress
      await _resetWeeklyProgress(user.uid);
      
      // Reset deck progress
      await _resetDeckProgress(user.uid);
      
      // Reset goal achievements
      await _resetGoalAchievements(user.uid);
      
      // Reset study streak
      await _resetStudyStreak(user.uid);

      print('Data reset completed successfully');
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  // Reset daily progress data
  static Future<void> _resetDailyProgress(String userId) async {
    try {
      final batch = _firestore.batch();
      final dailyProgressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyProgress');

      final snapshot = await dailyProgressRef.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Daily progress data reset');
    } catch (e) {
      print('Error resetting daily progress: $e');
    }
  }

  // Reset weekly progress data
  static Future<void> _resetWeeklyProgress(String userId) async {
    try {
      final batch = _firestore.batch();
      final weeklyProgressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('weeklyProgress');

      final snapshot = await weeklyProgressRef.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Weekly progress data reset');
    } catch (e) {
      print('Error resetting weekly progress: $e');
    }
  }

  // Reset deck progress data
  static Future<void> _resetDeckProgress(String userId) async {
    try {
      final batch = _firestore.batch();
      final deckProgressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('deckProgress');

      final snapshot = await deckProgressRef.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Deck progress data reset');
    } catch (e) {
      print('Error resetting deck progress: $e');
    }
  }

  // Reset goal achievements
  static Future<void> _resetGoalAchievements(String userId) async {
    try {
      final batch = _firestore.batch();
      final goalAchievementsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('goalAchievements');

      final snapshot = await goalAchievementsRef.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Goal achievements reset');
    } catch (e) {
      print('Error resetting goal achievements: $e');
    }
  }

  // Reset study streak
  static Future<void> _resetStudyStreak(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('streakData')
          .doc('current')
          .delete();
      
      print('Study streak reset');
    } catch (e) {
      print('Error resetting study streak: $e');
    }
  }

  // Get current progress data (for debugging)
  static Future<void> printCurrentProgressData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('=== CURRENT PROGRESS DATA ===');
      
      // Daily progress
      final dailySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyProgress')
          .get();
      
      print('Daily Progress Documents: ${dailySnapshot.docs.length}');
      for (final doc in dailySnapshot.docs) {
        final data = doc.data();
        print('  ${doc.id}: ${data['cardsStudied']} cards, ${data['duration']} minutes');
      }

      // Weekly progress
      final weeklySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyProgress')
          .get();
      
      print('Weekly Progress Documents: ${weeklySnapshot.docs.length}');
      for (final doc in weeklySnapshot.docs) {
        final data = doc.data();
        print('  ${doc.id}: ${data['cardsStudied']} cards, ${data['duration']} minutes');
      }

      print('=== END PROGRESS DATA ===');
    } catch (e) {
      print('Error printing progress data: $e');
    }
  }
}

