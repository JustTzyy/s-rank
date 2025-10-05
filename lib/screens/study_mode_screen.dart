import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../models/flashcard.dart';
import '../services/study_service.dart';
import '../services/flashcard_service.dart';
import '../services/preferences_service.dart';
import '../services/progress_tracking_service.dart';
import '../theme/app_theme.dart';

class StudyModeScreen extends StatefulWidget {
  final String deckId;
  final StudyMode mode;

  const StudyModeScreen({
    super.key,
    required this.deckId,
    this.mode = StudyMode.review,
  });

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen>
    with TickerProviderStateMixin {
  final StudyService _studyService = StudyService();
  final FlashcardService _flashcardService = FlashcardService();
  final PreferencesService _preferencesService = PreferencesService();
  final ProgressTrackingService _progressTrackingService = ProgressTrackingService();
  
  StudySession? _session;
  List<Flashcard> _flashcards = [];
  int _currentCardIndex = 0;
  bool _isAnswerRevealed = false;
  bool _isLoading = true;
  bool _isSessionComplete = false;
  
  // Study preferences
  StudyPreferences? _studyPreferences;
  
  // For different question types
  int? _selectedOptionIndex; // For multiple choice
  final TextEditingController _answerController = TextEditingController(); // For typing answers
  bool _isAnswerCorrect = false;
  
  late AnimationController _flipController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;
  late Animation<double> _progressAnimation;
  
  DateTime? _cardStartTime;
  Duration _totalStudyTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStudySession();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _progressController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startStudySession() async {
    try {
      setState(() => _isLoading = true);
      
      // Load study preferences
      _studyPreferences = await _preferencesService.getStudyPreferences();
      
      // Start study session
      _session = await _studyService.startStudySession(
        deckId: widget.deckId,
        userId: 'current_user', // TODO: Get from auth service
        mode: widget.mode,
      );
      
      // Load flashcards
      _flashcards = await _flashcardService.getFlashcardsForDeck(widget.deckId);
      
      if (_flashcards.isEmpty) {
        throw Exception('No flashcards available for study');
      }
      
      // Apply study preferences
      if (_studyPreferences?.shuffleCards == true) {
        _flashcards.shuffle();
      }
      
      setState(() {
        _isLoading = false;
        _cardStartTime = DateTime.now();
      });
      
      _progressController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('No cards are due for review yet') || 
            errorMessage.contains('No difficult cards found')) {
          _showNoCardsDialog(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting study session: $e')),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _checkAnswer() {
    if (_currentCardIndex >= _flashcards.length) return;
    
    final card = _flashcards[_currentCardIndex];
    bool isCorrect = false;
    
    switch (card.type) {
      case FlashcardType.basic:
        isCorrect = _checkBasicAnswer(card);
        break;
      case FlashcardType.multipleChoice:
        isCorrect = _checkMultipleChoiceAnswer(card);
        break;
      case FlashcardType.enumeration:
        isCorrect = _checkEnumerationAnswer(card);
        break;
      case FlashcardType.identification:
        isCorrect = _checkIdentificationAnswer(card);
        break;
    }
    
    setState(() {
      _isAnswerCorrect = isCorrect;
      _isAnswerRevealed = true;
    });
    _flipController.forward();
  }

  bool _checkBasicAnswer(Flashcard card) {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = card.back.toLowerCase();
    
    // Simple string comparison - you can make this more sophisticated
    return userAnswer == correctAnswer;
  }

  bool _checkMultipleChoiceAnswer(Flashcard card) {
    if (_selectedOptionIndex == null || card.correctOptionIndex == null) {
      return false;
    }
    return _selectedOptionIndex == card.correctOptionIndex;
  }

  bool _checkEnumerationAnswer(Flashcard card) {
    if (card.enumerationItems == null || card.enumerationItems!.isEmpty) {
      return false;
    }
    
    final userAnswer = _answerController.text.trim().toLowerCase();
    final userItems = userAnswer.split(',').map((item) => item.trim()).toSet();
    final correctItems = card.enumerationItems!.map((item) => item.toLowerCase()).toSet();
    
    // Check if all correct items are present (order doesn't matter)
    return correctItems.every((item) => userItems.contains(item));
  }

  bool _checkIdentificationAnswer(Flashcard card) {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = card.identifier?.toLowerCase() ?? card.back.toLowerCase();
    
    return userAnswer == correctAnswer;
  }

  void _rateCard(CardRating rating) async {
    if (_session == null || _currentCardIndex >= _flashcards.length) return;
    
    try {
      final card = _flashcards[_currentCardIndex];
      final timeSpent = DateTime.now().difference(_cardStartTime!);
      
      // Submit answer
      await _studyService.submitAnswer(
        sessionId: _session!.id!,
        cardId: card.id!,
        rating: rating,
        isCorrect: _isAnswerCorrect,
        timeSpent: timeSpent,
      );
      
      // Update total study time
      _totalStudyTime += timeSpent;
      
      // Move to next card or complete session
      if (_currentCardIndex + 1 >= _flashcards.length) {
        await _completeSession();
      } else {
        // Check if auto-advance is enabled
        if (_studyPreferences?.autoAdvance == true) {
          // Auto-advance after a short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _nextCard();
            }
          });
        } else {
          _nextCard();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rating card: $e')),
        );
      }
    }
  }

  void _nextCard() {
    setState(() {
      _currentCardIndex++;
      _isAnswerRevealed = false;
      _isAnswerCorrect = false;
      _selectedOptionIndex = null;
      _answerController.clear();
      _cardStartTime = DateTime.now();
    });
    
    _flipController.reset();
    _progressController.forward();
  }

  Future<void> _completeSession() async {
    try {
      if (_session != null) {
        _session = await _studyService.completeStudySession(_session!.id!);
        
        // Track progress based on user preferences
        await _progressTrackingService.trackStudySession(
          deckId: widget.deckId,
          duration: _totalStudyTime.inMinutes,
          cardsStudied: _flashcards.length,
          correctAnswers: _session?.correctAnswers ?? 0,
          incorrectAnswers: _session?.incorrectAnswers ?? 0,
          accuracy: _session?.score ?? 0.0,
        );
      }
      
      setState(() {
        _isSessionComplete = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isSessionComplete) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildCard(),
            ),
            _buildRatingButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showExitConfirmation(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _session?.modeText ?? 'Study Mode',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _flashcards.isEmpty 
                        ? '0/0' 
                        : '${_currentCardIndex + 1}/${_flashcards.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final progress = _flashcards.isEmpty 
                    ? 0.0 
                    : _progressAnimation.value * ((_currentCardIndex + 1) / _flashcards.length);
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  minHeight: 8,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    if (_currentCardIndex >= _flashcards.length) {
      return const Center(
        child: Text('No more cards'),
      );
    }

    final card = _flashcards[_currentCardIndex];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 500, // Increased height to prevent overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _isAnswerRevealed 
                ? _buildCardBack(card, key: const ValueKey('back'))
                : _buildCardFront(card, key: const ValueKey('front')),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(Flashcard card, {Key? key}) {
    return Container(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: card.typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(card.typeIcon, size: 16, color: card.typeColor),
                const SizedBox(width: 4),
                Text(
                  card.typeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: card.typeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Question
          Text(
            card.front,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Content based on type
          _buildQuestionContent(card),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(Flashcard card) {
    switch (card.type) {
      case FlashcardType.basic:
        return _buildBasicQuestion();
      case FlashcardType.multipleChoice:
        return _buildMultipleChoiceQuestion(card);
      case FlashcardType.enumeration:
        return _buildEnumerationQuestion();
      case FlashcardType.identification:
        return _buildIdentificationQuestion(card);
    }
  }

  Widget _buildBasicQuestion() {
    return Column(
      children: [
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text('Check Answer'),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceQuestion(Flashcard card) {
    if (card.options == null || card.options!.isEmpty) {
      return const Text('No options available');
    }

    return Column(
      children: [
        ...card.options!.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedOptionIndex == index;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedOptionIndex = index),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryPurple.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryPurple
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected 
                            ? AppTheme.primaryPurple
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryPurple
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${String.fromCharCode(65 + index)}. $option',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? AppTheme.primaryPurple
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _selectedOptionIndex != null ? _checkAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text('Check Answer'),
        ),
      ],
    );
  }

  Widget _buildEnumerationQuestion() {
    return Column(
      children: [
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: 'List the items (separated by commas)...',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text('Check Answer'),
        ),
      ],
    );
  }

  Widget _buildIdentificationQuestion(Flashcard card) {
    return Column(
      children: [
        if (card.imageUrl != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image,
                    color: Colors.grey[400],
                    size: 50,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        TextField(
          controller: _answerController,
          decoration: InputDecoration(
            hintText: 'What is this?',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          child: const Text('Check Answer'),
        ),
      ],
    );
  }

  Widget _buildCardBack(Flashcard card, {Key? key}) {
    return Container(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Result indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isAnswerCorrect 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAnswerCorrect ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isAnswerCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAnswerCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isAnswerCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Correct answer
          Text(
            'Correct Answer:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C6C6C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getCorrectAnswerText(card),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
          
          // Show user's answer if different
          if (!_isAnswerCorrect) ...[
            const SizedBox(height: 20),
            Text(
              'Your Answer:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C6C6C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getUserAnswerText(card),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 30),
          // How well did you know this?
          const Text(
            'How well did you know this?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6C6C6C),
            ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
      ),
    );
  }

  String _getCorrectAnswerText(Flashcard card) {
    switch (card.type) {
      case FlashcardType.basic:
        return card.back;
      case FlashcardType.multipleChoice:
        if (card.options != null && 
            card.correctOptionIndex != null && 
            card.correctOptionIndex! < card.options!.length) {
          return '${String.fromCharCode(65 + card.correctOptionIndex!)}. ${card.options![card.correctOptionIndex!]}';
        }
        return card.back;
      case FlashcardType.enumeration:
        if (card.enumerationItems != null && card.enumerationItems!.isNotEmpty) {
          return card.enumerationItems!.join(', ');
        }
        return card.back;
      case FlashcardType.identification:
        return card.identifier ?? card.back;
    }
  }

  String _getUserAnswerText(Flashcard card) {
    switch (card.type) {
      case FlashcardType.basic:
      case FlashcardType.enumeration:
      case FlashcardType.identification:
        return _answerController.text.trim().isEmpty 
            ? 'No answer provided' 
            : _answerController.text.trim();
      case FlashcardType.multipleChoice:
        if (_selectedOptionIndex != null && 
            card.options != null && 
            _selectedOptionIndex! < card.options!.length) {
          return '${String.fromCharCode(65 + _selectedOptionIndex!)}. ${card.options![_selectedOptionIndex!]}';
        }
        return 'No option selected';
    }
  }

  Widget _buildRatingButtons() {
    if (!_isAnswerRevealed) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_isAnswerCorrect) ...[
            // Correct answer - show confidence levels
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    'Hard',
                    CardRating.hard,
                    Colors.orange,
                    Icons.trending_down,
                    'Correct but difficult',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRatingButton(
                    'Good',
                    CardRating.good,
                    Colors.green,
                    Icons.check_circle,
                    'Correct and confident',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    'Easy',
                    CardRating.easy,
                    Colors.blue,
                    Icons.trending_up,
                    'Correct and easy',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(), // Empty space for alignment
                ),
              ],
            ),
          ] else ...[
            // Incorrect answer - show again option
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    'Again',
                    CardRating.again,
                    Colors.red,
                    Icons.refresh,
                    'Study this again',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(), // Empty space for alignment
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingButton(String label, CardRating rating, Color color, IconData icon, String description) {
    return GestureDetector(
      onTap: () => _rateCard(rating),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Completion icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              
              // Completion message
              const Text(
                'Study Session Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Statistics
              if (_session != null) ...[
                _buildStatCard('Cards Studied', '${_session!.completedCards}'),
                const SizedBox(height: 12),
                _buildStatCard('Accuracy', '${_session!.accuracy.toStringAsFixed(1)}%'),
                const SizedBox(height: 12),
                _buildStatCard('Score', '${_session!.score.toInt()}'),
                const SizedBox(height: 12),
                _buildStatCard('Best Streak', '${_session!.maxStreak}'),
              ],
              
              const SizedBox(height: 40),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                      child: const Text('Back to Deck'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Start new study session
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                      child: const Text('Study Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6C6C6C),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoCardsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Cards Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Try these alternatives:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Review All - Study all cards in this deck'),
            const Text('• Random - Study cards in random order'),
            const SizedBox(height: 16),
            const Text(
              'Cards become "due" after you study them and they need review based on spaced repetition.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Navigate to review all mode
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StudyModeScreen(
                    deckId: widget.deckId,
                    mode: StudyMode.review,
                  ),
                ),
              );
            },
            child: const Text('Review All'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Study Session'),
        content: const Text('Are you sure you want to exit? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Studying'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
