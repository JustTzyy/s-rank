import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/study_session.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flashcard_card.dart';
import '../widgets/enhanced_add_flashcard_modal.dart';
import '../widgets/edit_flashcard_modal.dart';
import 'study_mode_screen.dart';

class DeckDetailsScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailsScreen({
    super.key,
    required this.deck,
  });

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlashcardService _flashcardService = FlashcardService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Flashcard> _flashcards = [];
  List<Flashcard> _filteredFlashcards = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFlashcards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    try {
      setState(() => _isLoading = true);
      final flashcards = await _flashcardService.getFlashcardsForDeck(widget.deck.id!);
      setState(() {
        _flashcards = flashcards;
        _filteredFlashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flashcards: $e')),
        );
      }
    }
  }

  void _searchFlashcards(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFlashcards = _flashcards;
      } else {
        _filteredFlashcards = _flashcards.where((card) =>
          card.front.toLowerCase().contains(query.toLowerCase()) ||
          card.back.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
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
                  _buildFlashcardsTab(),
                  _buildStudyTab(),
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
                onTap: _showAddFlashcardModal,
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
            widget.deck.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_flashcards.length} flashcards',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6C6C6C),
            ),
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
          Tab(text: 'Flashcards'),
          Tab(text: 'Study'),
        ],
      ),
    );
  }

  Widget _buildFlashcardsTab() {
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
              : _filteredFlashcards.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredFlashcards.length,
                      itemBuilder: (context, index) {
                        final flashcard = _filteredFlashcards[index];
                        return FlashcardCard(
                          flashcard: flashcard,
                          onEdit: () => _showEditFlashcardModal(flashcard),
                          onDelete: () => _showDeleteConfirmation(flashcard),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStudyTab() {
    if (_flashcards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppTheme.primaryPurple.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No flashcards to study',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C6C6C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some flashcards first to start studying',
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
        children: [
          // Study mode options
          _buildStudyModeCard(
            'Review All',
            'Study all flashcards in this deck',
            Icons.school,
            Colors.blue,
            StudyMode.review,
          ),
          const SizedBox(height: 16),
          _buildStudyModeCard(
            'Due Cards',
            'Study only cards that are due for review',
            Icons.schedule,
            Colors.orange,
            StudyMode.due,
          ),
          const SizedBox(height: 16),
          _buildStudyModeCard(
            'Random',
            'Study cards in random order',
            Icons.shuffle,
            Colors.green,
            StudyMode.random,
          ),
          const SizedBox(height: 16),
          _buildStudyModeCard(
            'Difficult',
            'Focus on difficult cards only',
            Icons.warning,
            Colors.red,
            StudyMode.difficult,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyModeCard(String title, String description, IconData icon, Color color, StudyMode mode) {
    return GestureDetector(
      onTap: () => _startStudyMode(mode),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C6C6C),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _startStudyMode(StudyMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyModeScreen(
          deckId: widget.deck.id!,
          mode: mode,
        ),
      ),
    );
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
        onChanged: _searchFlashcards,
        decoration: const InputDecoration(
          hintText: 'Search flashcards...',
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
            Icons.quiz_outlined,
            size: 64,
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No flashcards yet' : 'No flashcards found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C6C6C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tap the + button to add your first flashcard'
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


  void _showAddFlashcardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedAddFlashcardModal(
        deckId: widget.deck.id!,
        onFlashcardAdded: () {
          _loadFlashcards();
        },
      ),
    );
  }

  void _showEditFlashcardModal(Flashcard flashcard) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditFlashcardModal(
        flashcard: flashcard,
        onFlashcardUpdated: () {
          _loadFlashcards();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Flashcard'),
        content: const Text('Are you sure you want to archive this flashcard? You can restore it later from the archive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteFlashcard(flashcard);
            },
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    try {
      await _flashcardService.archiveFlashcard(flashcard.id!);
      _loadFlashcards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard archived successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving flashcard: $e')),
        );
      }
    }
  }
}

class _AddFlashcardModal extends StatefulWidget {
  final String deckId;
  final VoidCallback? onFlashcardAdded;

  const _AddFlashcardModal({
    required this.deckId,
    this.onFlashcardAdded,
  });

  @override
  State<_AddFlashcardModal> createState() => _AddFlashcardModalState();
}

class _AddFlashcardModalState extends State<_AddFlashcardModal> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = false;
  int _selectedDifficulty = 3;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _addFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final flashcard = Flashcard(
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        deckId: widget.deckId,
        difficulty: _selectedDifficulty,
      );

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
                  'Add New Flashcard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Front Text Field
                TextFormField(
                  controller: _frontController,
                  decoration: InputDecoration(
                    labelText: 'Front',
                    hintText: 'Question or term',
                    prefixIcon: Icon(Icons.quiz, color: AppTheme.primaryPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the front text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Back Text Field
                TextFormField(
                  controller: _backController,
                  decoration: InputDecoration(
                    labelText: 'Back',
                    hintText: 'Answer or definition',
                    prefixIcon: Icon(Icons.lightbulb, color: AppTheme.primaryPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the back text';
                    }
                    return null;
                  },
                ),
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
}

