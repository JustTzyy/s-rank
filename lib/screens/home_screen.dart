import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../models/course.dart';
import '../widgets/add_course_modal.dart';
import '../widgets/edit_course_modal.dart';
import '../widgets/course_card.dart';
import '../widgets/search_bar_widget.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'course_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final user = _controller.currentUser;
          if (user == null) {
            return const Center(child: Text('No user logged in'));
          }
          
          return SafeArea(
            child: Column(
              children: [
                // Top Header with Gradient Background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPurple.withOpacity(0.05),
                        AppTheme.lightPurple.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primaryPurple.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.darkPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats Cards with Enhanced Design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsCards(),
                ),
                
                const SizedBox(height: 32),
                
                // Courses Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Courses',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _controller.hasSearchResults 
                                    ? '${_controller.coursesCount} results for "${_controller.searchQuery}"'
                                    : 'Your learning journey',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      SearchBarWidget(
                        initialValue: _controller.searchQuery,
                        onChanged: _controller.searchCourses,
                        onClear: _controller.clearSearch,
                        hintText: 'Search by title, description, or instructor...',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Courses List
                Expanded(
                  child: _controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _controller.courses.isEmpty
                          ? _buildEmptyState()
                          : _buildCoursesList(_controller.courses),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8F9FA),
              const Color(0xFFF5F5F5),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top border line with gradient
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE0E0E0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Decorative rounded rectangle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Floating Action Button inside footer
            Expanded(
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.darkPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _showAddCourseModal,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final profile = _controller.userProfile;
    final points = profile?['points'] ?? 0;
    final rank = profile?['rank'] ?? 'C';
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '$points',
            'Studied Card',
            AppTheme.primaryPurple,
            Icons.school,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            rank,
            'Current Rank',
            const Color(0xFFFFC107),
            Icons.emoji_events,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_controller.hasSearchResults) {
      // No search results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _controller.clearSearch,
              icon: Icon(
                Icons.clear,
                color: AppTheme.primaryPurple,
              ),
              label: Text(
                'Clear Search',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // No courses at all
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first course',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCoursesList(List<Course> courses) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          course: course,
          onTap: () => _onCourseCardTapped(course),
          onEdit: () => _onEditCourse(course),
          onDelete: () => _onDeleteCourse(course),
        );
      },
    );
  }

  void _showAddCourseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCourseModal(
        onCourseAdded: () {
          // Refresh handled automatically by stream
        },
      ),
    );
  }

  void _onCourseCardTapped(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(course: course),
      ),
    );
  }

  void _onEditCourse(Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCourseModal(
        course: course,
        onCourseUpdated: () {
          // Refresh handled automatically by stream
        },
      ),
    );
  }

  void _onDeleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Course',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${course.title}"?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _controller.deleteCourse(course.id!);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Course deleted successfully'),
                      backgroundColor: AppTheme.primaryPurple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting course: ${_controller.error ?? 'Unknown error'}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await _controller.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
