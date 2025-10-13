import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/course.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/course_service.dart';
import '../services/deck_service.dart';
import '../services/flashcard_service.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final CourseService _courseService = CourseService();
  final DeckService _deckService = DeckService();
  final FlashcardService _flashcardService = FlashcardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryPurple,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Archive',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Courses'),
            Tab(text: 'Decks'),
            Tab(text: 'Flashcards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArchivedCourses(),
          _buildArchivedDecks(),
          _buildArchivedFlashcards(),
        ],
      ),
    );
  }

  Widget _buildArchivedCourses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('createdby', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        // Filter archived courses in memory (where deletedAt is not null)
        final courses = snapshot.data?.docs
            .map((doc) => Course.fromFirestore(doc))
            .where((course) => course.deletedAt != null)
            .toList() ?? [];
        
        // Sort by deletedAt in memory
        courses.sort((a, b) {
          if (a.deletedAt == null && b.deletedAt == null) return 0;
          if (a.deletedAt == null) return 1;
          if (b.deletedAt == null) return -1;
          return b.deletedAt!.compareTo(a.deletedAt!);
        });

        if (courses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_outlined,
            title: 'No Archived Courses',
            subtitle: 'Deleted courses will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildArchivedCourseCard(course);
          },
        );
      },
    );
  }

  Widget _buildArchivedDecks() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder<List<Deck>>(
        future: _getUserArchivedDecks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final decks = snapshot.data ?? [];
          
          // Sort by deletedAt in memory
          decks.sort((a, b) {
            if (a.deletedAt == null && b.deletedAt == null) return 0;
            if (a.deletedAt == null) return 1;
            if (b.deletedAt == null) return -1;
            return b.deletedAt!.compareTo(a.deletedAt!);
          });

          if (decks.isEmpty) {
            return _buildEmptyState(
              icon: Icons.library_books_outlined,
              title: 'No Archived Decks',
              subtitle: 'Deleted decks will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return _buildArchivedDeckCard(deck);
            },
          );
        },
      ),
    );
  }

  Widget _buildArchivedFlashcards() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder<List<Flashcard>>(
        future: _getUserArchivedFlashcardsSimple(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final flashcards = snapshot.data ?? [];
        
        // Sort by deletedAt in memory
        flashcards.sort((a, b) {
          if (a.deletedAt == null && b.deletedAt == null) return 0;
          if (a.deletedAt == null) return 1;
          if (b.deletedAt == null) return -1;
          return b.deletedAt!.compareTo(a.deletedAt!);
        });

        if (flashcards.isEmpty) {
          return _buildEmptyState(
            icon: Icons.quiz_outlined,
            title: 'No Archived Flashcards',
            subtitle: 'Deleted flashcards will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flashcards.length,
          itemBuilder: (context, index) {
            final flashcard = flashcards[index];
            return _buildArchivedFlashcardCard(flashcard);
          },
        );
        },
      ),
    );
  }

  Widget _buildArchivedCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school,
            color: AppTheme.primaryPurple,
          ),
        ),
        title: Text(
          course.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Archived ${_formatDate(course.deletedAt)}',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCourseAction(value, course),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: AppTheme.primaryPurple),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Forever'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedDeckCard(Deck deck) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.library_books,
            color: AppTheme.primaryPurple,
          ),
        ),
        title: Text(
          deck.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deck.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Archived ${_formatDate(deck.deletedAt)}',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDeckAction(value, deck),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: AppTheme.primaryPurple),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Forever'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedFlashcardCard(Flashcard flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.quiz,
            color: AppTheme.primaryPurple,
          ),
        ),
        title: Text(
          flashcard.front,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flashcard.back,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Archived ${_formatDate(flashcard.deletedAt)}',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFlashcardAction(value, flashcard),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: AppTheme.primaryPurple),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Forever'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Future<List<Deck>> _getUserArchivedDecks() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get all courses created by the user
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('createdby', isEqualTo: currentUserId)
          .get();

      if (coursesSnapshot.docs.isEmpty) return [];

      // Get all deck IDs from user's courses
      final courseIds = coursesSnapshot.docs.map((doc) => doc.id).toList();
      
      // Handle whereIn limit (max 10 items)
      List<QueryDocumentSnapshot> allDecks = [];
      for (int i = 0; i < courseIds.length; i += 10) {
        final batch = courseIds.skip(i).take(10).toList();
        final decksSnapshot = await FirebaseFirestore.instance
            .collection('decks')
            .where('courseId', whereIn: batch)
            .get();
        allDecks.addAll(decksSnapshot.docs);
      }

      // Filter for archived decks
      final archivedDecks = <Deck>[];
      for (var doc in allDecks) {
        final data = doc.data() as Map<String, dynamic>;
        final deletedAt = data['deletedAt'];
        
        // Check if deck is archived
        if (deletedAt != null) {
          archivedDecks.add(Deck.fromFirestore(doc));
        }
      }

      return archivedDecks;
    } catch (e) {
      return [];
    }
  }

  Future<List<Flashcard>> _getUserArchivedFlashcardsSimple() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get all flashcards and filter in memory
      final allFlashcardsSnapshot = await FirebaseFirestore.instance
          .collection('flashcards')
          .get();

      // Filter for archived flashcards
      final archivedFlashcards = <Flashcard>[];
      
      for (var doc in allFlashcardsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final deletedAt = data['deletedAt'];
        final deckId = data['deckId'];
        
        // Check if flashcard is archived
        if (deletedAt != null) {
          // Check if this deck belongs to user's courses
          final deckDoc = await FirebaseFirestore.instance
              .collection('decks')
              .doc(deckId)
              .get();
          
          if (deckDoc.exists) {
            final deckData = deckDoc.data()!;
            final courseId = deckData['courseId'];
            
            // Check if course belongs to user
            final courseDoc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseId)
                .get();
            
            if (courseDoc.exists) {
              final courseData = courseDoc.data()!;
              final courseCreatedBy = courseData['createdby'];
              
              if (courseCreatedBy == currentUserId) {
                archivedFlashcards.add(Flashcard.fromFirestore(doc));
              }
            }
          }
        }
      }

      return archivedFlashcards;
    } catch (e) {
      return [];
    }
  }


  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleCourseAction(String action, Course course) async {
    if (action == 'restore') {
      await _restoreCourse(course);
    } else if (action == 'delete') {
      await _deleteCourseForever(course);
    }
  }

  void _handleDeckAction(String action, Deck deck) async {
    if (action == 'restore') {
      await _restoreDeck(deck);
    } else if (action == 'delete') {
      await _deleteDeckForever(deck);
    }
  }

  void _handleFlashcardAction(String action, Flashcard flashcard) async {
    if (action == 'restore') {
      await _restoreFlashcard(flashcard);
    } else if (action == 'delete') {
      await _deleteFlashcardForever(flashcard);
    }
  }

  Future<void> _restoreCourse(Course course) async {
    try {
      await _courseService.restoreArchivedCourse(course.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course "${course.title}" restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore course: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCourseForever(Course course) async {
    final confirmed = await _showDeleteConfirmationDialog(
      title: 'Delete Forever',
      content: 'Are you sure you want to permanently delete "${course.title}"? This action cannot be undone.',
    );

    if (confirmed) {
      try {
        await _courseService.deleteCourseForever(course.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course "${course.title}" deleted forever!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete course: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreDeck(Deck deck) async {
    try {
      await _deckService.restoreDeck(deck.id!);
      if (mounted) {
        setState(() {}); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "${deck.title}" restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDeckForever(Deck deck) async {
    final confirmed = await _showDeleteConfirmationDialog(
      title: 'Delete Forever',
      content: 'Are you sure you want to permanently delete "${deck.title}"? This action cannot be undone.',
    );

    if (confirmed) {
      try {
        await _deckService.deleteDeckForever(deck.id!);
        if (mounted) {
          setState(() {}); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deck "${deck.title}" deleted forever!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete deck: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _restoreFlashcard(Flashcard flashcard) async {
    try {
      await _flashcardService.restoreFlashcard(flashcard.id!);
      if (mounted) {
        setState(() {}); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flashcard restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore flashcard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFlashcardForever(Flashcard flashcard) async {
    final confirmed = await _showDeleteConfirmationDialog(
      title: 'Delete Forever',
      content: 'Are you sure you want to permanently delete this flashcard? This action cannot be undone.',
    );

    if (confirmed) {
      try {
        await _flashcardService.deleteFlashcardForever(flashcard.id!);
        if (mounted) {
          setState(() {}); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Flashcard deleted forever!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete flashcard: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    ) ?? false;
  }
}
