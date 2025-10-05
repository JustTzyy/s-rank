import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/rank.dart';
import '../services/course_service.dart';
import '../services/auth_service.dart';
import '../services/rank_service.dart';
import '../services/challenge_completion_service.dart';

class DashboardController extends ChangeNotifier {
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  final RankService _rankService = RankService();
  final ChallengeCompletionService _completionService = ChallengeCompletionService();

  List<Course> _courses = [];
  List<Course> _allCourses = []; // Store all courses for search
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _error;
  Map<String, dynamic>? _userProfile;
  
  // Rank and points data
  int _totalPoints = 0;
  Rank? _currentRank;
  int _studiedCards = 0;

  // Getters
  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  Map<String, dynamic>? get userProfile => _userProfile;
  int get coursesCount => _courses.length;
  bool get hasSearchResults => _searchQuery.isNotEmpty;
  
  // Rank and points getters
  int get totalPoints => _totalPoints;
  Rank? get currentRank => _currentRank;
  int get studiedCards => _studiedCards;
  
  // Get current user
  get currentUser => _authService.currentUser;

  // Initialize dashboard data
  Future<void> initialize() async {
    await Future.wait([
      loadCourses(),
      loadUserProfile(),
      loadRankAndPoints(),
    ]);
  }

  // Load courses from database for current user
  Future<void> loadCourses() async {
    try {
      _setLoading(true);
      final user = _authService.currentUser;
      if (user != null) {
        _allCourses = await _courseService.getCoursesForUser(user.uid);
        _courses = List.from(_allCourses);
      } else {
        _allCourses = [];
        _courses = [];
      }
      _setError(null);
    } on CourseException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to load courses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        _userProfile = await _authService.getUserProfile(user.uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  // Load rank and points data
  Future<void> loadRankAndPoints() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Get all user completions to calculate total points and studied cards
        int totalPoints = 0;
        int studiedCards = 0;
        Rank? currentRank;

        // Get all courses for this user
        final userCourses = await _courseService.getCoursesForUser(user.uid);
        
        // Method 1: Get points from user ranks (per course)
        for (final course in userCourses) {
          try {
            // Get user rank for this course
            final userRank = await _rankService.getUserRank(user.uid, course.id!);
            if (userRank != null) {
              totalPoints += userRank.totalPoints;
              studiedCards += userRank.totalQuestions;
              
              // Get the current rank
              if (currentRank == null) {
                currentRank = await _rankService.getRankById(userRank.currentRankId);
              }
            }
          } catch (e) {
            // Continue if one course fails
            print('Warning: Could not load rank for course ${course.id}: $e');
          }
        }

        // Method 2: Also get points from challenge completions (backup method)
        if (totalPoints == 0) {
          try {
            // Get all completions for this user across all courses
            for (final course in userCourses) {
              final completions = await _completionService.getUserCompletions(user.uid, course.id!);
              for (final completion in completions) {
                totalPoints += completion.pointsEarned;
                studiedCards += completion.totalQuestions;
              }
            }
          } catch (e) {
            print('Warning: Could not load completions: $e');
          }
        }

        // If still no rank found, get the rank for the total points
        if (currentRank == null && totalPoints > 0) {
          try {
            currentRank = await _rankService.getRankForPoints(totalPoints);
          } catch (e) {
            print('Warning: Could not get rank for points: $e');
          }
        }

        print('Dashboard loaded - Total Points: $totalPoints, Studied Cards: $studiedCards, Rank: ${currentRank?.name}');
        
        _totalPoints = totalPoints;
        _currentRank = currentRank;
        _studiedCards = studiedCards;
        
        // Update user profile with the calculated total points and rank
        if (totalPoints > 0 || currentRank != null) {
          try {
            await _authService.updateUserPointsAndRank(
              user.uid,
              totalPoints,
              currentRank?.name ?? 'C-Rank',
            );
            print('Updated user profile from dashboard - Points: $totalPoints, Rank: ${currentRank?.name ?? 'C-Rank'}');
          } catch (e) {
            print('Warning: Could not update user profile from dashboard: $e');
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Warning: Could not load rank and points: $e');
      // Set default values
      _totalPoints = 0;
      _currentRank = null;
      _studiedCards = 0;
    }
  }

  // Refresh rank and points data
  Future<void> refreshRankAndPoints() async {
    await loadRankAndPoints();
  }

  // Add a new course
  Future<bool> addCourse(Course course) async {
    try {
      _setLoading(true);
      await _courseService.addCourse(course);
      await loadCourses(); // Refresh the list
      return true;
    } on CourseException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to add course: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a course
  Future<bool> updateCourse(String id, Course course) async {
    try {
      _setLoading(true);
      await _courseService.updateCourse(id, course);
      await loadCourses(); // Refresh the list
      return true;
    } on CourseException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to update course: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a course
  Future<bool> deleteCourse(String id) async {
    try {
      _setLoading(true);
      await _courseService.deleteCourse(id);
      await loadCourses(); // Refresh the list
      return true;
    } on CourseException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to delete course: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search courses locally (faster) and fallback to server search
  void searchCourses(String query) {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      // Show all courses when search is empty
      _courses = List.from(_allCourses);
      _isSearching = false;
    } else {
      // Local search first (faster)
      _isSearching = true;
      _courses = _allCourses.where((course) {
        final titleMatch = course.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final descriptionMatch = course.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final instructorMatch = course.instructor?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return titleMatch || descriptionMatch || instructorMatch;
      }).toList();
    }
    
    notifyListeners();
  }

  // Server-side search (more comprehensive)
  Future<void> searchCoursesOnServer(String query) async {
    if (query.isEmpty) {
      await loadCourses();
      return;
    }

    try {
      _setLoading(true);
      _searchQuery = query.trim();
      _isSearching = true;
      
      final user = _authService.currentUser;
      if (user != null) {
        _courses = await _courseService.searchCoursesForUser(user.uid, _searchQuery);
      } else {
        _courses = [];
      }
      _setError(null);
    } on CourseException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to search courses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear search and show all courses
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _courses = List.from(_allCourses);
    notifyListeners();
  }

  // Get courses stream for real-time updates (current user only)
  Stream<List<Course>> getCoursesStream() {
    final user = _authService.currentUser;
    if (user != null) {
      return _courseService.getCoursesStreamForUser(user.uid);
    } else {
      return Stream.value([]);
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _courses.clear();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    }
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

}
