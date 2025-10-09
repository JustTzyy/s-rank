import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/rank.dart';
import '../models/challenge_completion.dart';
import '../services/flashcard_service.dart';
import '../services/rank_service.dart';
import '../services/challenge_completion_service.dart';
import '../services/auth_service.dart';
import '../services/progress_tracking_service.dart';
import '../theme/app_theme.dart';

class ChallengeScreen extends StatefulWidget {
  final Deck deck;
  final String courseId;
  final VoidCallback? onChallengeCompleted;

  const ChallengeScreen({
    super.key,
    required this.deck,
    required this.courseId,
    this.onChallengeCompleted,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService();
  final RankService _rankService = RankService();
  final ChallengeCompletionService _completionService = ChallengeCompletionService();
  final AuthService _authService = AuthService();
  final ProgressTrackingService _progressTrackingService = ProgressTrackingService();
  
  List<Flashcard> _flashcards = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isQuizComplete = false;
  bool _isAnswerRevealed = false;
  
  // Quiz state
  int _totalPoints = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  UserRank? _userRank;
  Rank? _currentRank;
  
  // Completion tracking
  DateTime? _sessionStartTime;
  int _sessionPoints = 0;
  String? _currentUserId;
  
  // Answer state
  int? _selectedOptionIndex;
  final TextEditingController _answerController = TextEditingController();
  bool _isAnswerCorrect = false;
  DateTime? _questionStartTime;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuiz();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadQuiz() async {
    try {
      setState(() => _isLoading = true);
      
      // Load flashcards for the deck
      _flashcards = await _flashcardService.getFlashcardsForDeck(widget.deck.id!);
      
      if (_flashcards.isEmpty) {
        throw Exception('No questions available in this deck');
      }
      
      // Shuffle questions
      _flashcards.shuffle();
      
      // Get current user ID
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      _currentUserId = user.uid;
      
      // Load user's current rank
      _userRank = await _rankService.getUserRank(_currentUserId!, widget.courseId);
      if (_userRank != null) {
        _currentRank = await _rankService.getRankById(_userRank!.currentRankId);
      }
      
      setState(() {
        _isLoading = false;
        _sessionStartTime = DateTime.now();
        _questionStartTime = DateTime.now();
        // Reset session counters for new challenge
        _correctAnswers = 0;
        _sessionPoints = 0;
        _currentQuestionIndex = 0;
      });
      
      _progressController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _checkAnswer() {
    if (_currentQuestionIndex >= _flashcards.length) return;
    
    final card = _flashcards[_currentQuestionIndex];
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
  }

  bool _checkBasicAnswer(Flashcard card) {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = card.back.toLowerCase();
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
    
    return correctItems.every((item) => userItems.contains(item));
  }

  bool _checkIdentificationAnswer(Flashcard card) {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = card.identifier?.toLowerCase() ?? card.back.toLowerCase();
    return userAnswer == correctAnswer;
  }

  void _submitAnswer() async {
    if (_currentQuestionIndex >= _flashcards.length) return;
    
    try {
      final card = _flashcards[_currentQuestionIndex];
      final timeSpent = DateTime.now().difference(_questionStartTime!);
      
      // Calculate points
      final pointsEarned = _rankService.calculatePoints(
        difficulty: card.difficulty,
        isCorrect: _isAnswerCorrect,
        timeSpent: timeSpent,
        basePoints: 1, // Not used in new system, but required parameter
      );
      
      // Track session points
      _sessionPoints += pointsEarned;
      
            // Track correct answers
      if (_isAnswerCorrect) {
        _correctAnswers++;
      }
      
      // Update user rank
      _userRank = await _rankService.updateUserPoints(
        userId: _currentUserId!,
        courseId: widget.courseId,
        pointsEarned: pointsEarned,
        isCorrect: _isAnswerCorrect,
      );
      
      // Update current rank
      _currentRank = await _rankService.getRankById(_userRank!.currentRankId);
      
      // Update quiz state
      setState(() {
        _totalPoints = _userRank!.totalPoints;
        // Don't reset _correctAnswers here - it should only increment during the session
        _totalQuestions = _userRank!.totalQuestions;
      });
      
      // Move to next question or complete quiz
      if (_currentQuestionIndex + 1 >= _flashcards.length) {
        await _completeQuiz();
      } else {
        _nextQuestion();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error submitting answer';
        if (e.toString().contains('No rank found for points')) {
          errorMessage = 'Ranking system is not set up. Please try again.';
        } else if (e.toString().contains('Failed to update user points')) {
          errorMessage = 'Failed to save your progress. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry the answer submission
                _submitAnswer();
              },
            ),
          ),
        );
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _isAnswerRevealed = false;
      _isAnswerCorrect = false;
      _selectedOptionIndex = null;
      _answerController.clear();
      _questionStartTime = DateTime.now();
    });
    
    _progressController.forward();
  }

  Future<void> _completeQuiz() async {
    try {
      // Save completion data
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final accuracy = _flashcards.length > 0 ? (_correctAnswers / _flashcards.length) * 100 : 0.0;
      
      final completion = ChallengeCompletion(
        userId: _currentUserId!,
        courseId: widget.courseId,
        deckId: widget.deck.id!,
        completedAt: DateTime.now(),
        score: _correctAnswers,
        totalQuestions: _flashcards.length,
        correctAnswers: _correctAnswers,
        accuracy: accuracy,
        timeSpent: sessionDuration,
        pointsEarned: _sessionPoints,
      );
      
      await _completionService.saveCompletion(completion);
      
      // Track progress for challenge completion
      try {
        await _progressTrackingService.trackStudySession(
          deckId: widget.deck.id!,
          duration: sessionDuration.inMinutes,
          cardsStudied: _flashcards.length,
          correctAnswers: _correctAnswers,
          incorrectAnswers: _flashcards.length - _correctAnswers,
          accuracy: accuracy,
        );
        print('Challenge progress tracked successfully');
      } catch (e) {
        print('Warning: Could not track challenge progress: $e');
      }
      
      // Update user profile with total points and rank
      try {
        await _authService.updateUserPointsAndRank(
          _currentUserId!,
          _userRank?.totalPoints ?? 0,
          _currentRank?.name ?? 'C-Rank',
        );
        print('Updated user profile - Points: ${_userRank?.totalPoints ?? 0}, Rank: ${_currentRank?.name ?? 'C-Rank'}');
      } catch (e) {
        print('Warning: Could not update user profile: $e');
      }
      
      setState(() {
        _isQuizComplete = true;
      });
      
      // Notify parent that challenge is completed
      if (widget.onChallengeCompleted != null) {
        widget.onChallengeCompleted!();
      }
    } catch (e) {
      // Still show completion screen even if saving fails
      setState(() {
        _isQuizComplete = true;
      });
      
      // Notify parent that challenge is completed even if saving failed
      if (widget.onChallengeCompleted != null) {
        widget.onChallengeCompleted!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge completed! (Progress may not be saved)'),
            backgroundColor: Colors.orange,
          ),
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

    if (_isQuizComplete) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildQuestionCard(_flashcards[_currentQuestionIndex]),
            ),
            _buildActionButtons(),
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
                'Challenge: ${widget.deck.title}',
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
                    '${_currentQuestionIndex + 1}/${_flashcards.length}',
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
              return LinearProgressIndicator(
                value: _progressAnimation.value * ((_currentQuestionIndex + 1) / _flashcards.length),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                minHeight: 8,
              );
            },
          ),
          const SizedBox(height: 16),
          // Points and correct display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Points', '$_sessionPoints', Colors.blue),
              _buildStatItem('Correct', '$_correctAnswers/${_flashcards.length}', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuestionCard(Flashcard card, {Key? key}) {
    if (_currentQuestionIndex >= _flashcards.length) {
      return const Center(
        child: Text('No more questions'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        key: key,
        width: double.infinity,
        height: 500,
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
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _isAnswerRevealed 
                ? _buildAnswerCard(card, key: const ValueKey('answer'))
                : _buildQuestionCardInner(card, key: const ValueKey('question')),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCardInner(Flashcard card, {Key? key}) {
    return Container(
      key: key,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Type and difficulty indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: card.difficultyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: card.difficultyColor),
                      const SizedBox(width: 4),
                      Text(
                        card.difficultyText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: card.difficultyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildAnswerCard(Flashcard card, {Key? key}) {
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

  Widget _buildActionButtons() {
    if (!_isAnswerRevealed) return const SizedBox.shrink();
    
    final isLastQuestion = _currentQuestionIndex + 1 >= _flashcards.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress indicator
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentQuestionIndex + 1) / _flashcards.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.darkPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Question counter
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_flashcards.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          // Next Question button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion 
                    ? const Color(0xFF4CAF50) 
                    : AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: isLastQuestion 
                    ? const Color(0xFF4CAF50).withOpacity(0.4)
                    : AppTheme.primaryPurple.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLastQuestion) ...[
                    const Icon(
                      Icons.check_circle_outline,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    isLastQuestion ? 'Finish Challenge' : 'Next Question',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  Icons.emoji_events,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              
              // Completion message
              const Text(
                'Challenge Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildColoredStatCard(
                      '$_sessionPoints',
                      'Points',
                      const Color(0xFF2196F3), // Blue
                      Icons.stars,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildColoredStatCard(
                      '$_correctAnswers/${_flashcards.length}',
                      'Correct',
                      const Color(0xFF4CAF50), // Green
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
              
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
                      child: const Text('Back to Course'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Start new challenge
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
                      child: const Text('Try Again'),
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

  Widget _buildColoredStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            blurRadius: 10,
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

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Challenge'),
        content: const Text('Are you sure you want to exit? Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: const Text(
              'Exit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
