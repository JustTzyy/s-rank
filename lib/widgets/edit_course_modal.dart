import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';

class EditCourseModal extends StatefulWidget {
  final Course course;
  final VoidCallback? onCourseUpdated;

  const EditCourseModal({
    super.key,
    required this.course,
    this.onCourseUpdated,
  });

  @override
  State<EditCourseModal> createState() => _EditCourseModalState();
}

class _EditCourseModalState extends State<EditCourseModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructorController = TextEditingController();
  
  final CourseService _courseService = CourseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing course data
    _titleController.text = widget.course.title;
    _descriptionController.text = widget.course.description;
    _instructorController.text = widget.course.instructor ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Update Course',
      content: 'Are you sure you want to update "${_titleController.text.trim()}"?',
      confirmText: 'Update Course',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final updatedCourse = widget.course.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim().isEmpty 
            ? null 
            : _instructorController.text.trim(),
      );

      await _courseService.updateCourse(widget.course.id!, updatedCourse);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course updated successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        widget.onCourseUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating course: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Edit Course',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Course Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Course Title',
                    hintText: 'e.g., Introduction to Flutter',
                    prefixIcon: Icon(Icons.book, color: AppTheme.primaryPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                    ),
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
                ),
                const SizedBox(height: 16),
                
                // Course Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe what this course covers...',
                    prefixIcon: Icon(Icons.description, color: AppTheme.primaryPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a course description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Instructor Field (Optional)
                TextFormField(
                  controller: _instructorController,
                  decoration: InputDecoration(
                    labelText: 'Instructor (Optional)',
                    hintText: 'e.g., Dr. Smith, John Doe',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateCourse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Update Course',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
