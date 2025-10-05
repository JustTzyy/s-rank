import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';

class ProgressSettingsScreen extends StatefulWidget {
  const ProgressSettingsScreen({super.key});

  @override
  State<ProgressSettingsScreen> createState() => _ProgressSettingsScreenState();
}

class _ProgressSettingsScreenState extends State<ProgressSettingsScreen> {
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Progress Tracking Settings
  bool _trackStudyTime = true;
  bool _trackAccuracy = true;
  bool _trackStreaks = true;
  bool _trackPoints = true;
  bool _showProgressCharts = true;
  bool _showDailyGoals = true;

  // Goal Settings
  int _dailyStudyGoal = 30; // minutes
  int _weeklyStudyGoal = 180; // minutes
  int _dailyCardGoal = 20;
  int _weeklyCardGoal = 100;
  bool _enableGoalReminders = true;

  // Progress Display Settings
  bool _showProgressInHome = true;
  bool _showProgressInCourses = true;
  bool _showProgressInDecks = true;
  String _progressDisplayMode = 'Detailed'; // Simple, Detailed, Advanced
  final List<String> _displayModes = ['Simple', 'Detailed', 'Advanced'];

  // Data Retention Settings
  int _dataRetentionDays = 365; // days
  bool _autoArchiveOldData = true;
  bool _exportProgressData = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _preferencesService.getProgressSettings();
      if (settings != null) {
        // Progress Tracking Settings
        _trackStudyTime = settings.trackStudyTime;
        _trackAccuracy = settings.trackAccuracy;
        _trackStreaks = settings.trackStreaks;
        _trackPoints = settings.trackPoints;
        _showProgressCharts = settings.showProgressCharts;
        _showDailyGoals = settings.showDailyGoals;
        
        // Goal Settings
        _dailyStudyGoal = settings.dailyStudyGoal;
        _weeklyStudyGoal = settings.weeklyStudyGoal;
        _dailyCardGoal = settings.dailyCardGoal;
        _weeklyCardGoal = settings.weeklyCardGoal;
        _enableGoalReminders = settings.enableGoalReminders;
        
        // Progress Display Settings
        _showProgressInHome = settings.showProgressInHome;
        _showProgressInCourses = settings.showProgressInCourses;
        _showProgressInDecks = settings.showProgressInDecks;
        _progressDisplayMode = settings.progressDisplayMode;
        
        // Data Retention Settings
        _dataRetentionDays = settings.dataRetentionDays;
        _autoArchiveOldData = settings.autoArchiveOldData;
        _exportProgressData = settings.exportProgressData;
      }
    } catch (e) {
      print('Error loading progress settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final settings = ProgressSettings(
        trackStudyTime: _trackStudyTime,
        trackAccuracy: _trackAccuracy,
        trackStreaks: _trackStreaks,
        trackPoints: _trackPoints,
        showProgressCharts: _showProgressCharts,
        showDailyGoals: _showDailyGoals,
        dailyStudyGoal: _dailyStudyGoal,
        weeklyStudyGoal: _weeklyStudyGoal,
        dailyCardGoal: _dailyCardGoal,
        weeklyCardGoal: _weeklyCardGoal,
        enableGoalReminders: _enableGoalReminders,
        showProgressInHome: _showProgressInHome,
        showProgressInCourses: _showProgressInCourses,
        showProgressInDecks: _showProgressInDecks,
        progressDisplayMode: _progressDisplayMode,
        dataRetentionDays: _dataRetentionDays,
        autoArchiveOldData: _autoArchiveOldData,
        exportProgressData: _exportProgressData,
      );
      
      await _preferencesService.saveProgressSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
          'Progress Settings',
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
              onPressed: _saveSettings,
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
                  // Progress Tracking Section
                  _buildSectionCard(
                    title: 'Progress Tracking',
                    icon: Icons.analytics,
                    children: [
                      SwitchListTile(
                        title: const Text('Track Study Time'),
                        subtitle: const Text('Monitor time spent studying'),
                        value: _trackStudyTime,
                        onChanged: (value) {
                          setState(() => _trackStudyTime = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Track Accuracy'),
                        subtitle: const Text('Monitor correct/incorrect answers'),
                        value: _trackAccuracy,
                        onChanged: (value) {
                          setState(() => _trackAccuracy = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Track Streaks'),
                        subtitle: const Text('Monitor consecutive study days'),
                        value: _trackStreaks,
                        onChanged: (value) {
                          setState(() => _trackStreaks = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Track Points'),
                        subtitle: const Text('Monitor points earned from studying'),
                        value: _trackPoints,
                        onChanged: (value) {
                          setState(() => _trackPoints = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Progress Charts'),
                        subtitle: const Text('Display visual progress charts'),
                        value: _showProgressCharts,
                        onChanged: (value) {
                          setState(() => _showProgressCharts = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Daily Goals'),
                        subtitle: const Text('Display daily goal progress'),
                        value: _showDailyGoals,
                        onChanged: (value) {
                          setState(() => _showDailyGoals = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Goal Settings Section
                  _buildSectionCard(
                    title: 'Study Goals',
                    icon: Icons.flag,
                    children: [
                      ListTile(
                        title: const Text('Daily Study Goal'),
                        subtitle: Text('$_dailyStudyGoal minutes'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _dailyStudyGoal > 5
                                  ? () => setState(() => _dailyStudyGoal -= 5)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _dailyStudyGoal < 120
                                  ? () => setState(() => _dailyStudyGoal += 5)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Weekly Study Goal'),
                        subtitle: Text('$_weeklyStudyGoal minutes'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _weeklyStudyGoal > 30
                                  ? () => setState(() => _weeklyStudyGoal -= 30)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _weeklyStudyGoal < 600
                                  ? () => setState(() => _weeklyStudyGoal += 30)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Daily Card Goal'),
                        subtitle: Text('$_dailyCardGoal cards'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _dailyCardGoal > 5
                                  ? () => setState(() => _dailyCardGoal -= 5)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _dailyCardGoal < 100
                                  ? () => setState(() => _dailyCardGoal += 5)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        title: const Text('Weekly Card Goal'),
                        subtitle: Text('$_weeklyCardGoal cards'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _weeklyCardGoal > 50
                                  ? () => setState(() => _weeklyCardGoal -= 25)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _weeklyCardGoal < 500
                                  ? () => setState(() => _weeklyCardGoal += 25)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Goal Reminders'),
                        subtitle: const Text('Get notified about goal progress'),
                        value: _enableGoalReminders,
                        onChanged: (value) {
                          setState(() => _enableGoalReminders = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Display Settings Section
                  _buildSectionCard(
                    title: 'Display Settings',
                    icon: Icons.visibility,
                    children: [
                      ListTile(
                        title: const Text('Progress Display Mode'),
                        subtitle: const Text('Choose how progress is displayed'),
                        trailing: DropdownButton<String>(
                          value: _progressDisplayMode,
                          onChanged: (value) {
                            setState(() => _progressDisplayMode = value!);
                          },
                          items: _displayModes.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            );
                          }).toList(),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Show Progress in Home'),
                        subtitle: const Text('Display progress on home screen'),
                        value: _showProgressInHome,
                        onChanged: (value) {
                          setState(() => _showProgressInHome = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Progress in Courses'),
                        subtitle: const Text('Display progress in course screens'),
                        value: _showProgressInCourses,
                        onChanged: (value) {
                          setState(() => _showProgressInCourses = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Progress in Decks'),
                        subtitle: const Text('Display progress in deck screens'),
                        value: _showProgressInDecks,
                        onChanged: (value) {
                          setState(() => _showProgressInDecks = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Retention Section
                  _buildSectionCard(
                    title: 'Data Retention',
                    icon: Icons.storage,
                    children: [
                      ListTile(
                        title: const Text('Data Retention Period'),
                        subtitle: Text('$_dataRetentionDays days'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _dataRetentionDays > 30
                                  ? () => setState(() => _dataRetentionDays -= 30)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _dataRetentionDays < 1095
                                  ? () => setState(() => _dataRetentionDays += 30)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Auto Archive Old Data'),
                        subtitle: const Text('Automatically archive data older than retention period'),
                        value: _autoArchiveOldData,
                        onChanged: (value) {
                          setState(() => _autoArchiveOldData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Export Progress Data'),
                        subtitle: const Text('Allow exporting of progress data'),
                        value: _exportProgressData,
                        onChanged: (value) {
                          setState(() => _exportProgressData = value);
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
