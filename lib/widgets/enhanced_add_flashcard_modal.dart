import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';

class EnhancedAddFlashcardModal extends StatefulWidget {
  final String deckId;
  final VoidCallback? onFlashcardAdded;

  const EnhancedAddFlashcardModal({
    super.key,
    required this.deckId,
    this.onFlashcardAdded,
  });

  @override
  State<EnhancedAddFlashcardModal> createState() => _EnhancedAddFlashcardModalState();
}

class _EnhancedAddFlashcardModalState extends State<EnhancedAddFlashcardModal> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _identifierController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final FlashcardService _flashcardService = FlashcardService();
  
  bool _isLoading = false;
  int _selectedDifficulty = 3;
  FlashcardType _selectedType = FlashcardType.basic;
  
  // For multiple choice
  final List<TextEditingController> _optionControllers = [];
  int? _correctOptionIndex;
  
  // For enumeration
  final List<TextEditingController> _enumerationControllers = [];

  @override
  void initState() {
    super.initState();
    _addOptionController();
    _addEnumerationController();
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

  Future<void> _addFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Flashcard flashcard;
      
      switch (_selectedType) {
        case FlashcardType.basic:
          flashcard = Flashcard(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            deckId: widget.deckId,
            type: _selectedType,
            difficulty: _selectedDifficulty,
          );
          break;
          
        case FlashcardType.multipleChoice:
          final options = _optionControllers
              .map((controller) => controller.text.trim())
              .where((text) => text.isNotEmpty)
              .toList();
          flashcard = Flashcard(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            deckId: widget.deckId,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            options: options,
            correctOptionIndex: _correctOptionIndex,
          );
          break;
          
        case FlashcardType.enumeration:
          final items = _enumerationControllers
              .map((controller) => controller.text.trim())
              .where((text) => text.isNotEmpty)
              .toList();
          flashcard = Flashcard(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            deckId: widget.deckId,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            enumerationItems: items,
          );
          break;
          
        case FlashcardType.identification:
          flashcard = Flashcard(
            front: _frontController.text.trim(),
            back: _backController.text.trim(),
            deckId: widget.deckId,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            imageUrl: _imageUrlController.text.trim().isNotEmpty 
                ? _imageUrlController.text.trim() 
                : null,
            identifier: _identifierController.text.trim().isNotEmpty 
                ? _identifierController.text.trim() 
                : null,
          );
          break;
      }

      await _flashcardService.addFlashcard(flashcard);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard added successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        widget.onFlashcardAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding flashcard: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  'Add New Flashcard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Type Selection
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
                    final isSelected = _selectedType == type;
                    final typeColor = _getTypeColor(type);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
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
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Content based on type
                _buildTypeSpecificContent(),
                const SizedBox(height: 16),
                
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
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addFlashcard,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add Flashcard'),
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
    switch (_selectedType) {
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
          decoration: InputDecoration(
            labelText: 'Question',
            hintText: 'Enter your question',
            prefixIcon: Icon(Icons.quiz, color: AppTheme.primaryPurple),
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
          decoration: InputDecoration(
            labelText: 'Answer',
            hintText: 'Enter the answer',
            prefixIcon: Icon(Icons.lightbulb, color: AppTheme.primaryPurple),
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
          decoration: InputDecoration(
            labelText: 'Question',
            hintText: 'Enter your question',
            prefixIcon: Icon(Icons.quiz, color: AppTheme.primaryPurple),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a question';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              children: _optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Option ${String.fromCharCode(65 + index)}',
                            hintText: 'Enter option text',
                            prefixIcon: Icon(
                              Icons.radio_button_unchecked,
                              color: _correctOptionIndex == index 
                                  ? Colors.green 
                                  : AppTheme.primaryPurple,
                            ),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _correctOptionIndex == index 
                                ? Colors.green 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _correctOptionIndex == index 
                                ? Icons.check_circle 
                                : Icons.radio_button_unchecked,
                            color: _correctOptionIndex == index 
                                ? Colors.white 
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_optionControllers.length > 2)
                        GestureDetector(
                          onTap: () => _removeOptionController(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.red[600],
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _addOptionController,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: AppTheme.primaryPurple,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Option',
                  style: TextStyle(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnumerationContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: InputDecoration(
            labelText: 'Topic',
            hintText: 'Enter the topic to enumerate',
            prefixIcon: Icon(Icons.topic, color: AppTheme.primaryPurple),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a topic';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Items to Enumerate',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              children: _enumerationControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Item ${index + 1}',
                            hintText: 'Enter item text',
                            prefixIcon: Icon(Icons.format_list_numbered, color: AppTheme.primaryPurple),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter item text';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_enumerationControllers.length > 1)
                        GestureDetector(
                          onTap: () => _removeEnumerationController(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.red[600],
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _addEnumerationController,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Item',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationContent() {
    return Column(
      children: [
        TextFormField(
          controller: _frontController,
          decoration: InputDecoration(
            labelText: 'What to identify',
            hintText: 'e.g., "Identify this organ", "Name this structure"',
            prefixIcon: Icon(Icons.search, color: AppTheme.primaryPurple),
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
          decoration: InputDecoration(
            labelText: 'Image URL (Optional)',
            hintText: 'Enter image URL',
            prefixIcon: Icon(Icons.image, color: AppTheme.primaryPurple),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _identifierController,
          decoration: InputDecoration(
            labelText: 'Answer/Identifier',
            hintText: 'Enter the correct answer',
            prefixIcon: Icon(Icons.lightbulb, color: AppTheme.primaryPurple),
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

  Color _getTypeColor(FlashcardType type) {
    switch (type) {
      case FlashcardType.basic:
        return Colors.blue;
      case FlashcardType.multipleChoice:
        return Colors.green;
      case FlashcardType.enumeration:
        return Colors.orange;
      case FlashcardType.identification:
        return Colors.purple;
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
        return Icons.image_search;
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
}
