import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/deck.dart';
import '../models/challenge_completion.dart';
import '../services/deck_service.dart';
import '../services/challenge_completion_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/deck_card.dart';
import '../widgets/add_deck_modal.dart';
import '../widgets/edit_deck_modal.dart';
import 'deck_details_screen.dart';
import 'challenge_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  final VoidCallback? onDataChanged;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.onDataChanged,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeckService _deckService = DeckService();
  final ChallengeCompletionService _completionService = ChallengeCompletionService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Deck> _decks = [];
  List<Deck> _filteredDecks = [];
  List<ChallengeCompletion> _completions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDecks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    try {
      setState(() => _isLoading = true);
      final decks = await _deckService.getDecksForCourse(widget.course.id!);
      
      // Try to load completions, but don't fail if it doesn't work
      List<ChallengeCompletion> completions = [];
      try {
        final user = _authService.currentUser;
        if (user != null) {
          completions = await _completionService.getUserCompletions(user.uid, widget.course.id!);
        }
      } catch (e) {
        print('Warning: Could not load completions: $e');
        // Continue without completions
      }
      
      setState(() {
        _decks = decks;
        _filteredDecks = decks;
        _completions = completions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading decks: $e')),
        );
      }
    }
  }

  void _searchDecks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDecks = _decks;
      } else {
        _filteredDecks = _decks.where((deck) =>
          deck.title.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  // Check if a deck is completed
  ChallengeCompletion? _getDeckCompletion(String deckId) {
    try {
      return _completions.firstWhere((completion) => completion.deckId == deckId);
    } catch (e) {
      return null;
    }
  }

  // Check if a deck is completed
  bool _isDeckCompleted(String deckId) {
    return _getDeckCompletion(deckId) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDecksTab(),
                  _buildChallengesTab(),
                ],
              ),
            ),
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
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showAddDeckModal,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.course.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'Decks'),
          Tab(text: 'Challenges'),
        ],
      ),
    );
  }

  Widget _buildDecksTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchBar(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredDecks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredDecks.length,
                      itemBuilder: (context, index) {
                        final deck = _filteredDecks[index];
                        return DeckCard(
                          deck: deck,
                          onTap: () => _navigateToDeckDetails(deck),
                          onEdit: () => _showEditDeckModal(deck),
                          onDelete: () => _showDeleteConfirmation(deck),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChallengesTab() {
    if (_decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppTheme.primaryPurple.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No decks available for challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C6C6C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create some decks first to start challenges',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Challenge Decks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test your knowledge and earn points!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Decks list
          Expanded(
            child: ListView.builder(
              itemCount: _decks.length,
              itemBuilder: (context, index) {
                final deck = _decks[index];
                return _buildChallengeDeckCard(deck);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeDeckCard(Deck deck) {
    final isCompleted = _isDeckCompleted(deck.id!);
    final completion = _getDeckCompletion(deck.id!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleChallengeTap(deck, isCompleted),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryPurple.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Challenge icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: AppTheme.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Deck info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deck.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C6C6C),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isCompleted) ...[
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed - ${completion?.statusText ?? 'Done'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.emoji_events,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Earn points & climb ranks',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primaryPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleChallengeTap(Deck deck, bool isCompleted) {
    if (isCompleted) {
      _showTryAgainModal(deck);
    } else {
      _startChallenge(deck);
    }
  }

  void _startChallenge(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChallengeScreen(
          deck: deck,
          courseId: widget.course.id!,
          onChallengeCompleted: () {
            // Refresh completions when challenge is completed
            _loadDecks();
            // Notify parent to refresh dashboard
            if (widget.onDataChanged != null) {
              widget.onDataChanged!();
            }
          },
        ),
      ),
    ).then((_) {
      // Refresh completions when returning from challenge
      _loadDecks();
    });
  }

  void _showTryAgainModal(Deck deck) {
    final completion = _getDeckCompletion(deck.id!);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: AppTheme.primaryPurple,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Challenge Completed!'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'You\'ve already completed "${deck.title}"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (completion != null) ...[
              _buildCompletionStat('Score', '${completion.correctAnswers}/${completion.totalQuestions}'),
              const SizedBox(height: 8),
              _buildCompletionStat('Accuracy', '${completion.accuracy.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              _buildCompletionStat('Points Earned', '${completion.pointsEarned}'),
              const SizedBox(height: 8),
              _buildCompletionStat('Time', _formatDuration(completion.timeSpent)),
              const SizedBox(height: 16),
            ],
            const Text(
              'Would you like to try again?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C6C6C),
              ),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startChallenge(deck);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C6C6C),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchDecks,
        decoration: const InputDecoration(
          hintText: 'Search decks...',
          hintStyle: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF9E9E9E),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2C2C2C),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No decks yet' : 'No decks found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C6C6C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tap the + button to add your first deck'
                : 'Try adjusting your search terms',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  void _navigateToDeckDetails(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeckDetailsScreen(deck: deck),
      ),
    );
  }


  void _showDeleteConfirmation(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Deck'),
        content: const Text('Are you sure you want to archive this deck? This will move the deck and all its flashcards to the archive. You can restore it later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteDeck(deck);
            },
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    try {
      await _deckService.archiveDeck(deck.id!);
      _loadDecks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck archived successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving deck: $e')),
        );
      }
    }
  }

  void _showEditDeckModal(Deck deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditDeckModal(
        deck: deck,
        onDeckUpdated: () {
          _loadDecks();
        },
      ),
    );
  }

  void _showAddDeckModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDeckModal(
        courseId: widget.course.id ?? '',
        onDeckAdded: () {
          _loadDecks();
        },
      ),
    );
  }
}
