import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AddCourseModal extends StatefulWidget {
  final VoidCallback? onCourseAdded;

  const AddCourseModal({
    super.key,
    this.onCourseAdded,
  });

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  final _courseService = CourseService();
  final _authService = AuthService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _addCourse() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Add Course',
      content: 'Are you sure you want to add "${_titleController.text.trim()}"?',
      confirmText: 'Add Course',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _showErrorMessage('User not logged in');
        return;
      }

      final course = Course(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: user.uid, // Set as current user's ID
        instructor: _instructorController.text.trim().isEmpty 
            ? null 
            : _instructorController.text.trim(), // Optional instructor
      );

      await _courseService.addCourse(course);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
        widget.onCourseAdded?.call();
      }
    } on CourseException catch (e) {
      if (mounted) {
        _showErrorMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course added successfully!'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHandleBar(),
                const SizedBox(height: 24),
                _buildTitle(),
                const SizedBox(height: 24),
                _buildTitleField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildInstructorField(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Add New Course',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Course Title',
        hintText: 'e.g., Flutter Development',
        prefixIcon: Icon(Icons.book, color: AppTheme.primaryPurple),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a course title';
        }
        if (value.trim().length < 3) {
          return 'Course title must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Brief description of the course',
        prefixIcon: Icon(Icons.description, color: AppTheme.primaryPurple),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        if (value.trim().length < 10) {
          return 'Description must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildInstructorField() {
    return TextFormField(
      controller: _instructorController,
      decoration: InputDecoration(
        labelText: 'Instructor (Optional)',
        hintText: 'e.g., Dr. Smith',
        prefixIcon: Icon(Icons.person, color: AppTheme.primaryPurple),
        helperText: 'Leave empty if you are the instructor',
      ),
      validator: (value) {
        // Instructor is now optional
        if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
          return 'Instructor name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _cancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addCourse,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Add Course'),
          ),
        ),
      ],
    );
  }
}
