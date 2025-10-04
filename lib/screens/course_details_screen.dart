import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import '../theme/app_theme.dart';
import '../widgets/deck_card.dart';
import 'deck_details_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeckService _deckService = DeckService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Deck> _decks = [];
  List<Deck> _filteredDecks = [];
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
      setState(() {
        _decks = decks;
        _filteredDecks = decks;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  _buildFlashcardsTab(),
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
          Tab(text: 'Flashcards'),
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

  Widget _buildFlashcardsTab() {
    return const Center(
      child: Text(
        'Flashcards Tab\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF6C6C6C),
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
        title: const Text('Delete Deck'),
        content: const Text('Are you sure you want to delete this deck? This will also delete all flashcards in the deck.'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    try {
      await _deckService.deleteDeck(deck.id!);
      _loadDecks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck deleted successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting deck: $e')),
        );
      }
    }
  }

  void _showEditDeckModal(Deck deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditDeckModal(
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
      builder: (context) => _AddDeckModal(
        courseId: widget.course.id ?? '',
        onDeckAdded: () {
          _loadDecks();
        },
      ),
    );
  }
}

class _AddDeckModal extends StatefulWidget {
  final String courseId;
  final VoidCallback? onDeckAdded;

  const _AddDeckModal({
    required this.courseId,
    this.onDeckAdded,
  });

  @override
  State<_AddDeckModal> createState() => _AddDeckModalState();
}

class _AddDeckModalState extends State<_AddDeckModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final DeckService _deckService = DeckService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addDeck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final deck = Deck(
        title: _titleController.text.trim(),
        courseId: widget.courseId,
      );

      await _deckService.addDeck(deck);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck added successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        widget.onDeckAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding deck: $e')),
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
                  'Add New Deck',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Deck Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Deck Title',
                    hintText: 'e.g., Vocabulary, Formulas, etc.',
                    prefixIcon: Icon(Icons.folder, color: AppTheme.primaryPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a deck title';
                    }
                    if (value.trim().length < 2) {
                      return 'Deck title must be at least 2 characters';
                    }
                    return null;
                  },
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
                        onPressed: _isLoading ? null : _addDeck,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add Deck'),
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

class _EditDeckModal extends StatefulWidget {
  final Deck deck;
  final VoidCallback? onDeckUpdated;

  const _EditDeckModal({
    required this.deck,
    this.onDeckUpdated,
  });

  @override
  State<_EditDeckModal> createState() => _EditDeckModalState();
}

class _EditDeckModalState extends State<_EditDeckModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final DeckService _deckService = DeckService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.deck.title;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _updateDeck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedDeck = widget.deck.copyWith(
        title: _titleController.text.trim(),
      );

      await _deckService.updateDeck(widget.deck.id!, updatedDeck);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck updated successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
        widget.onDeckUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating deck: $e')),
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
                  'Edit Deck',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Deck Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Deck Title',
                    hintText: 'e.g., Vocabulary, Formulas, etc.',
                    prefixIcon: Icon(Icons.folder, color: AppTheme.primaryPurple),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a deck title';
                    }
                    if (value.trim().length < 2) {
                      return 'Deck title must be at least 2 characters';
                    }
                    return null;
                  },
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
                        onPressed: _isLoading ? null : _updateDeck,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Update Deck'),
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


