import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';

class EditFlashcardModal extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback? onFlashcardUpdated;

  const EditFlashcardModal({
    super.key,
    required this.flashcard,
    this.onFlashcardUpdated,
  });

  @override
  State<EditFlashcardModal> createState() => _EditFlashcardModalState();
}

class _EditFlashcardModalState extends State<EditFlashcardModal> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _identifierController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = false;
  int _selectedDifficulty = 3;
  
  // For multiple choice
  final List<TextEditingController> _optionControllers = [];
  int? _correctOptionIndex;
  
  // For enumeration
  final List<TextEditingController> _enumerationControllers = [];

  @override
  void initState() {
    super.initState();
    _frontController.text = widget.flashcard.front;
    _backController.text = widget.flashcard.back;
    _selectedDifficulty = widget.flashcard.difficulty;
    
    // Initialize based on flashcard type
    _initializeFlashcardType();
  }
  
  void _initializeFlashcardType() {
    switch (widget.flashcard.type) {
      case FlashcardType.multipleChoice:
        if (widget.flashcard.options != null) {
          for (int i = 0; i < widget.flashcard.options!.length; i++) {
            _optionControllers.add(TextEditingController(text: widget.flashcard.options![i]));
          }
        }
        _correctOptionIndex = widget.flashcard.correctOptionIndex;
        break;
      case FlashcardType.enumeration:
        if (widget.flashcard.enumerationItems != null) {
          for (int i = 0; i < widget.flashcard.enumerationItems!.length; i++) {
            _enumerationControllers.add(TextEditingController(text: widget.flashcard.enumerationItems![i]));
          }
        }
        break;
      case FlashcardType.identification:
        _identifierController.text = widget.flashcard.identifier ?? '';
        _imageUrlController.text = widget.flashcard.imageUrl ?? '';
        break;
      case FlashcardType.basic:
      default:
        // Basic type - no additional initialization needed
        break;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _identifierController.dispose();
    _imageUrlController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    for (var controller in _enumerationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Update Flashcard',
      content: 'Are you sure you want to update this flashcard?',
      confirmText: 'Update Flashcard',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      Flashcard updatedFlashcard;
      
      switch (widget.flashcard.type) {
        case FlashcardType.multipleChoice:
          final options = _optionControllers.map((controller) => controller.text.trim()).toList();
          updatedFlashcard = widget.flashcard.copyWith(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            difficulty: _selectedDifficulty,
            options: options,
            correctOptionIndex: _correctOptionIndex,
          );
          break;
        case FlashcardType.enumeration:
          final enumerationItems = _enumerationControllers.map((controller) => controller.text.trim()).toList();
          updatedFlashcard = widget.flashcard.copyWith(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            difficulty: _selectedDifficulty,
            enumerationItems: enumerationItems,
          );
          break;
        case FlashcardType.identification:
          updatedFlashcard = widget.flashcard.copyWith(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            difficulty: _selectedDifficulty,
            identifier: _identifierController.text.trim(),
            imageUrl: _imageUrlController.text.trim(),
          );
          break;
        case FlashcardType.basic:
        default:
          updatedFlashcard = widget.flashcard.copyWith(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            difficulty: _selectedDifficulty,
          );
          break;
      }

      await _flashcardService.updateFlashcard(widget.flashcard.id!, updatedFlashcard);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard updated successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        widget.onFlashcardUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating flashcard: $e')),
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
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
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
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
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
                  'Edit Flashcard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Type Display (Read-only for edit)
                Text(
                  'Flashcard Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FlashcardType.values.map((type) {
                    final isSelected = widget.flashcard.type == type;
                    final typeColor = _getTypeColor(type);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? typeColor.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? typeColor : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            size: 16,
                            color: isSelected ? typeColor : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTypeText(type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? typeColor : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Type-specific content
                _buildTypeSpecificContent(),
                const SizedBox(height: 24),
                
                // Difficulty Selector
                Text(
                  'Difficulty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final difficulty = index + 1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = difficulty),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedDifficulty == difficulty
                                ? AppTheme.primaryPurple
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            difficulty.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedDifficulty == difficulty
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                
                
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateFlashcard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                            : const Text('Update Flashcard'),
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

  Widget _buildTypeSpecificContent() {
    switch (widget.flashcard.type) {
      case FlashcardType.basic:
        return _buildBasicContent();
      case FlashcardType.multipleChoice:
        return _buildMultipleChoiceContent();
      case FlashcardType.enumeration:
        return _buildEnumerationContent();
      case FlashcardType.identification:
        return _buildIdentificationContent();
    }
  }

  Widget _buildBasicContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: _getInputDecoration(
            labelText: 'Question',
            hintText: 'Enter your question',
            prefixIcon: Icons.quiz,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a question';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _backController,
          decoration: _getInputDecoration(
            labelText: 'Answer',
            hintText: 'Enter the answer',
            prefixIcon: Icons.lightbulb,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an answer';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: _getInputDecoration(
            labelText: 'Question',
            hintText: 'Enter your question',
            prefixIcon: Icons.quiz,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a question';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _backController,
          decoration: _getInputDecoration(
            labelText: 'Answer',
            hintText: 'Enter the answer',
            prefixIcon: Icons.lightbulb,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an answer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addOptionController,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Option'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_optionControllers.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${String.fromCharCode(65 + index)}',
                      hintText: 'Enter option text',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: Icon(
                        Icons.radio_button_unchecked,
                        color: _correctOptionIndex == index 
                            ? Colors.green 
                            : AppTheme.primaryPurple,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter option text';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _correctOptionIndex = index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _correctOptionIndex == index 
                          ? Colors.green 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      color: _correctOptionIndex == index 
                          ? Colors.white 
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (_optionControllers.length > 2)
                  IconButton(
                    onPressed: () => _removeOptionController(index),
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEnumerationContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: _getInputDecoration(
            labelText: 'Topic',
            hintText: 'Enter the topic to enumerate',
            prefixIcon: Icons.topic,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a topic';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _backController,
          decoration: _getInputDecoration(
            labelText: 'Answer',
            hintText: 'Enter the answer',
            prefixIcon: Icons.lightbulb,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an answer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enumeration Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addEnumerationController,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_enumerationControllers.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _enumerationControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Item ${index + 1}',
                      hintText: 'Enter item text',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.format_list_numbered, color: AppTheme.primaryPurple),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item text';
                      }
                      return null;
                    },
                  ),
                ),
                if (_enumerationControllers.length > 1)
                  IconButton(
                    onPressed: () => _removeEnumerationController(index),
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIdentificationContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: _getInputDecoration(
            labelText: 'What to identify',
            hintText: 'e.g., "Identify this organ", "Name this structure"',
            prefixIcon: Icons.search,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter what to identify';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _imageUrlController,
          decoration: _getInputDecoration(
            labelText: 'Image URL (Optional)',
            hintText: 'Enter image URL',
            prefixIcon: Icons.image,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _identifierController,
          decoration: _getInputDecoration(
            labelText: 'Answer/Identifier',
            hintText: 'Enter the correct answer',
            prefixIcon: Icons.lightbulb,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the answer';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryPurple),
      filled: true,
      fillColor: AppTheme.backgroundColor,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppTheme.primaryPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Color _getTypeColor(FlashcardType type) {
    switch (type) {
      case FlashcardType.basic:
        return AppTheme.primaryPurple;
      case FlashcardType.multipleChoice:
        return Colors.blue;
      case FlashcardType.enumeration:
        return Colors.green;
      case FlashcardType.identification:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(FlashcardType type) {
    switch (type) {
      case FlashcardType.basic:
        return Icons.quiz;
      case FlashcardType.multipleChoice:
        return Icons.radio_button_checked;
      case FlashcardType.enumeration:
        return Icons.format_list_numbered;
      case FlashcardType.identification:
        return Icons.search;
    }
  }

  String _getTypeText(FlashcardType type) {
    switch (type) {
      case FlashcardType.basic:
        return 'Basic';
      case FlashcardType.multipleChoice:
        return 'Multiple Choice';
      case FlashcardType.enumeration:
        return 'Enumeration';
      case FlashcardType.identification:
        return 'Identification';
    }
  }

  void _addOptionController() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOptionController(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        if (_correctOptionIndex == index) {
          _correctOptionIndex = null;
        } else if (_correctOptionIndex != null && _correctOptionIndex! > index) {
          _correctOptionIndex = _correctOptionIndex! - 1;
        }
      });
    }
  }

  void _addEnumerationController() {
    setState(() {
      _enumerationControllers.add(TextEditingController());
    });
  }

  void _removeEnumerationController(int index) {
    if (_enumerationControllers.length > 1) {
      setState(() {
        _enumerationControllers[index].dispose();
        _enumerationControllers.removeAt(index);
      });
    }
  }
}
