import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseService {
  static CourseService? _instance;
  
  factory CourseService() {
    _instance ??= CourseService._internal();
    return _instance!;
  }
  
  CourseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'courses';

  // Get reference to courses collection
  CollectionReference get _coursesCollection => 
      _firestore.collection(_collectionName);

  // Stream of courses for current user (excluding soft-deleted)
  Stream<List<Course>> getCoursesStreamForUser(String userId) {
    return _coursesCollection
        .where('createdby', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .where((course) => !course.isDeleted) // Filter in memory
          .toList();
    });
  }

  // Get all courses for current user (excluding soft-deleted)
  Future<List<Course>> getCoursesForUser(String userId) async {
    try {
      final snapshot = await _coursesCollection
          .where('createdby', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .where((course) => !course.isDeleted && course.deletedAt == null) // Filter out deleted and archived
          .toList();
    } catch (e) {
      throw CourseException('Failed to fetch courses: $e');
    }
  }

  // Stream of all courses (admin function)
  Stream<List<Course>> getAllCoursesStream() {
    return _coursesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    });
  }

  // Get all courses as a future (admin function)
  Future<List<Course>> getAllCourses() async {
    try {
      final snapshot = await _coursesCollection.get();
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    } catch (e) {
      throw CourseException('Failed to fetch courses: $e');
    }
  }

  // Get a specific course by ID
  Future<Course?> getCourseById(String id) async {
    try {
      final doc = await _coursesCollection.doc(id).get();
      if (doc.exists) {
        return Course.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw CourseException('Failed to fetch course: $e');
    }
  }

  // Add a new course
  Future<String> addCourse(Course course) async {
    try {
      final docRef = await _coursesCollection.add(course.toMap());
      return docRef.id;
    } catch (e) {
      throw CourseException('Failed to add course: $e');
    }
  }

  // Update an existing course
  Future<void> updateCourse(String id, Course course) async {
    try {
      final updateData = {
        'title': course.title,
        'description': course.description,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (course.instructor != null) {
        updateData['instructor'] = course.instructor!;
      }
      
      await _coursesCollection.doc(id).update(updateData);
    } catch (e) {
      throw CourseException('Failed to update course: $e');
    }
  }

  // Soft delete a course
  Future<void> deleteCourse(String id) async {
    try {
      await _coursesCollection.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CourseException('Failed to delete course: $e');
    }
  }

  // Hard delete a course (permanently remove)
  Future<void> hardDeleteCourse(String id) async {
    try {
      await _coursesCollection.doc(id).delete();
    } catch (e) {
      throw CourseException('Failed to permanently delete course: $e');
    }
  }

  // Restore a soft-deleted course
  Future<void> restoreCourse(String id) async {
    try {
      await _coursesCollection.doc(id).update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
      });
    } catch (e) {
      throw CourseException('Failed to restore course: $e');
    }
  }

  // Search courses by title for current user
  Future<List<Course>> searchCoursesForUser(String userId, String query) async {
    try {
      final snapshot = await _coursesCollection
          .where('createdby', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .where((course) => !course.isDeleted && 
                           course.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw CourseException('Failed to search courses: $e');
    }
  }

  // Search all courses by title (admin function)
  Future<List<Course>> searchAllCourses(String query) async {
    try {
      final snapshot = await _coursesCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    } catch (e) {
      throw CourseException('Failed to search courses: $e');
    }
  }

  // Get courses by instructor
  Future<List<Course>> getCoursesByInstructor(String instructor) async {
    try {
      final snapshot = await _coursesCollection
          .where('createdby', isEqualTo: instructor)
          .get();
      return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
    } catch (e) {
      throw CourseException('Failed to fetch courses by instructor: $e');
    }
  }

  // Get courses count
  Future<int> getCoursesCount() async {
    try {
      final snapshot = await _coursesCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      throw CourseException('Failed to get courses count: $e');
    }
  }

  // Archive course (soft delete) - cascades to decks and flashcards
  Future<void> archiveCourse(String courseId) async {
    try {
      // First, archive the course
      await _coursesCollection.doc(courseId).update({
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      // Then archive all decks in this course
      await _archiveAllDecksInCourse(courseId);
    } catch (e) {
      throw CourseException('Failed to archive course: $e');
    }
  }

  // Restore course from archive - only restores the course itself
  Future<void> restoreArchivedCourse(String courseId) async {
    try {
      // Only restore the course, not the decks and flashcards
      await _coursesCollection.doc(courseId).update({
        'deletedAt': FieldValue.delete(),
      });
    } catch (e) {
      throw CourseException('Failed to restore archived course: $e');
    }
  }

  // Delete course forever (hard delete)
  Future<void> deleteCourseForever(String courseId) async {
    try {
      await _coursesCollection.doc(courseId).delete();
    } catch (e) {
      throw CourseException('Failed to delete course forever: $e');
    }
  }

  // Helper method to archive all decks in a course
  Future<void> _archiveAllDecksInCourse(String courseId) async {
    try {
      final decksCollection = FirebaseFirestore.instance.collection('decks');
      final flashcardsCollection = FirebaseFirestore.instance.collection('flashcards');
      
      // Get all decks in this course
      final decksSnapshot = await decksCollection
          .where('courseId', isEqualTo: courseId)
          .where('deletedAt', isNull: true) // Only get non-archived decks
          .get();
      
      // Archive each deck and its flashcards
      for (final deckDoc in decksSnapshot.docs) {
        final deckId = deckDoc.id;
        
        // Archive all flashcards in this deck first
        final flashcardsSnapshot = await flashcardsCollection
            .where('deckId', isEqualTo: deckId)
            .where('deletedAt', isNull: true) // Only get non-archived flashcards
            .get();
        
        final batch = FirebaseFirestore.instance.batch();
        for (final flashcardDoc in flashcardsSnapshot.docs) {
          batch.update(flashcardDoc.reference, {
            'deletedAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Archive the deck
        batch.update(deckDoc.reference, {
          'deletedAt': FieldValue.serverTimestamp(),
        });
        
        await batch.commit();
      }
    } catch (e) {
      throw CourseException('Failed to archive all decks in course: $e');
    }
  }

}

// Custom exception class for course operations
class CourseException implements Exception {
  final String message;
  CourseException(this.message);

  @override
  String toString() => 'CourseException: $message';
}
