import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';

class StudyPreferencesScreen extends StatefulWidget {
  const StudyPreferencesScreen({super.key});

  @override
  State<StudyPreferencesScreen> createState() => _StudyPreferencesScreenState();
}

class _StudyPreferencesScreenState extends State<StudyPreferencesScreen> {
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Study Reminder Settings
  bool _studyRemindersEnabled = true;
  TimeOfDay _studyReminderTime = const TimeOfDay(hour: 19, minute: 0);
  List<String> _selectedReminderDays = ['Monday', 'Wednesday', 'Friday'];
  final List<String> _weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  // Difficulty Settings
  String _defaultDifficulty = 'Medium';
  final List<String> _difficultyLevels = ['Easy', 'Medium', 'Hard'];
  bool _adaptiveDifficulty = true;
  bool _showHints = true;
  int _maxHintsPerCard = 3;

  // Study Session Settings
  int _sessionDuration = 25; // minutes
  int _breakDuration = 5; // minutes
  bool _autoAdvance = true;
  bool _shuffleCards = true;
  bool _repeatIncorrect = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final preferences = await _preferencesService.getStudyPreferences();
      if (preferences != null) {
        // Study Reminder Settings
        _studyRemindersEnabled = preferences.studyRemindersEnabled;
        _studyReminderTime = TimeOfDay(
          hour: preferences.reminderHour,
          minute: preferences.reminderMinute,
        );
        _selectedReminderDays = preferences.selectedReminderDays;
        
        // Difficulty Settings
        _defaultDifficulty = preferences.defaultDifficulty;
        _adaptiveDifficulty = preferences.adaptiveDifficulty;
        _showHints = preferences.showHints;
        _maxHintsPerCard = preferences.maxHintsPerCard;
        
        // Study Session Settings
        _sessionDuration = preferences.sessionDuration;
        _breakDuration = preferences.breakDuration;
        _autoAdvance = preferences.autoAdvance;
        _shuffleCards = preferences.shuffleCards;
        _repeatIncorrect = preferences.repeatIncorrect;
      }
    } catch (e) {
      print('Error loading study preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    try {
      final preferences = StudyPreferences(
        studyRemindersEnabled: _studyRemindersEnabled,
        reminderHour: _studyReminderTime.hour,
        reminderMinute: _studyReminderTime.minute,
        selectedReminderDays: _selectedReminderDays,
        defaultDifficulty: _defaultDifficulty,
        adaptiveDifficulty: _adaptiveDifficulty,
        showHints: _showHints,
        maxHintsPerCard: _maxHintsPerCard,
        sessionDuration: _sessionDuration,
        breakDuration: _breakDuration,
        autoAdvance: _autoAdvance,
        shuffleCards: _shuffleCards,
        repeatIncorrect: _repeatIncorrect,
      );
      
      await _preferencesService.saveStudyPreferences(preferences);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _studyReminderTime,
    );
    
    if (picked != null && picked != _studyReminderTime) {
      setState(() => _studyReminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryPurple,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Study Preferences',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Study Reminders Section
                  _buildSectionCard(
                    title: 'Study Reminders',
                    icon: Icons.notifications,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Study Reminders'),
                        subtitle: const Text('Get notified to study at your preferred time'),
                        value: _studyRemindersEnabled,
                        onChanged: (value) {
                          setState(() => _studyRemindersEnabled = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      if (_studyRemindersEnabled) ...[
                        ListTile(
                          title: const Text('Reminder Time'),
                          subtitle: Text(_studyReminderTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: _selectReminderTime,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Reminder Days',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _weekDays.map((day) {
                            final isSelected = _selectedReminderDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedReminderDays.add(day);
                                  } else {
                                    _selectedReminderDays.remove(day);
                                  }
                                });
                              },
                              selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryPurple,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Difficulty Settings Section
                  _buildSectionCard(
                    title: 'Difficulty Settings',
                    icon: Icons.trending_up,
                    children: [
                      ListTile(
                        title: const Text('Default Difficulty'),
                        subtitle: const Text('Choose the default difficulty for new flashcards'),
                        trailing: DropdownButton<String>(
                          value: _defaultDifficulty,
                          onChanged: (value) {
                            setState(() => _defaultDifficulty = value!);
                          },
                          items: _difficultyLevels.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Adaptive Difficulty'),
                        subtitle: const Text('Automatically adjust difficulty based on performance'),
                        value: _adaptiveDifficulty,
                        onChanged: (value) {
                          setState(() => _adaptiveDifficulty = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Hints'),
                        subtitle: const Text('Display hints when studying flashcards'),
                        value: _showHints,
                        onChanged: (value) {
                          setState(() => _showHints = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      if (_showHints)
                        ListTile(
                          title: const Text('Max Hints Per Card'),
                          subtitle: Slider(
                            value: _maxHintsPerCard.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _maxHintsPerCard.toString(),
                            onChanged: (value) {
                              setState(() => _maxHintsPerCard = value.round());
                            },
                            activeColor: AppTheme.primaryPurple,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Study Session Settings Section
                  _buildSectionCard(
                    title: 'Study Session Settings',
                    icon: Icons.timer,
                    children: [
                      ListTile(
                        title: const Text('Session Duration'),
                        subtitle: Text('$_sessionDuration minutes'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _sessionDuration > 5
                                  ? () => setState(() => _sessionDuration -= 5)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _sessionDuration < 60
                                  ? () => setState(() => _sessionDuration += 5)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Break Duration'),
                        subtitle: Text('$_breakDuration minutes'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _breakDuration > 1
                                  ? () => setState(() => _breakDuration -= 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _breakDuration < 30
                                  ? () => setState(() => _breakDuration += 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Auto Advance'),
                        subtitle: const Text('Automatically move to next card after answering'),
                        value: _autoAdvance,
                        onChanged: (value) {
                          setState(() => _autoAdvance = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Shuffle Cards'),
                        subtitle: const Text('Randomize card order during study sessions'),
                        value: _shuffleCards,
                        onChanged: (value) {
                          setState(() => _shuffleCards = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Repeat Incorrect'),
                        subtitle: const Text('Show incorrect cards again in the same session'),
                        value: _repeatIncorrect,
                        onChanged: (value) {
                          setState(() => _repeatIncorrect = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
