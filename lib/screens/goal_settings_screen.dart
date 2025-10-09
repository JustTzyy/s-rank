import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/goal_tracking_service.dart';
import '../utils/data_reset_helper.dart';

class GoalSettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const GoalSettingsScreen({super.key, this.onDataChanged});

  @override
  State<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends State<GoalSettingsScreen> {
  final GoalTrackingService _goalTrackingService = GoalTrackingService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Goal Settings
  int _dailyStudyGoal = 30; // minutes
  int _dailyCardGoal = 20; // cards
  int _weeklyStudyGoal = 180; // minutes
  int _weeklyCardGoal = 100; // cards

  @override
  void initState() {
    super.initState();
    _loadGoalSettings();
  }

  Future<void> _loadGoalSettings() async {
    try {
      setState(() => _isLoading = true);
      
      // Load current goal settings from Firestore
      final settings = await _goalTrackingService.getGoalSettings();
      if (settings != null) {
        setState(() {
          _dailyStudyGoal = settings.dailyStudyGoal;
          _dailyCardGoal = settings.dailyCardGoal;
          _weeklyStudyGoal = settings.weeklyStudyGoal;
          _weeklyCardGoal = settings.weeklyCardGoal;
        });
      }
    } catch (e) {
      print('Error loading goal settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoalSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final settings = GoalSettings(
        dailyStudyGoal: _dailyStudyGoal,
        dailyCardGoal: _dailyCardGoal,
        weeklyStudyGoal: _weeklyStudyGoal,
        weeklyCardGoal: _weeklyCardGoal,
      );
      
      await _goalTrackingService.saveGoalSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent to refresh progress dashboard
        if (widget.onDataChanged != null) {
          widget.onDataChanged!();
        }
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
          'Goal Settings',
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
              onPressed: _saveGoalSettings,
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
                  // Daily Goals Section
                  _buildSectionCard(
                    title: 'Daily Goals',
                    icon: Icons.today,
                    children: [
                      _buildGoalItem(
                        title: 'Daily Study Time',
                        subtitle: 'Minutes to study per day',
                        value: _dailyStudyGoal,
                        min: 5,
                        max: 120,
                        step: 5,
                        unit: 'minutes',
                        onChanged: (value) => setState(() => _dailyStudyGoal = value),
                      ),
                      const SizedBox(height: 16),
                      _buildGoalItem(
                        title: 'Daily Cards',
                        subtitle: 'Cards to study per day',
                        value: _dailyCardGoal,
                        min: 5,
                        max: 100,
                        step: 5,
                        unit: 'cards',
                        onChanged: (value) => setState(() => _dailyCardGoal = value),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Weekly Goals Section
                  _buildSectionCard(
                    title: 'Weekly Goals',
                    icon: Icons.calendar_view_week,
                    children: [
                      _buildGoalItem(
                        title: 'Weekly Study Time',
                        subtitle: 'Minutes to study per week',
                        value: _weeklyStudyGoal,
                        min: 30,
                        max: 600,
                        step: 30,
                        unit: 'minutes',
                        onChanged: (value) => setState(() => _weeklyStudyGoal = value),
                      ),
                      const SizedBox(height: 16),
                      _buildGoalItem(
                        title: 'Weekly Cards',
                        subtitle: 'Cards to study per week',
                        value: _weeklyCardGoal,
                        min: 50,
                        max: 500,
                        step: 25,
                        unit: 'cards',
                        onChanged: (value) => setState(() => _weeklyCardGoal = value),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Reset Section
                  _buildDataResetCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Info Section
                  _buildInfoCard(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: children),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required int step,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > min ? () => onChanged(value - step) : null,
              style: IconButton.styleFrom(
                backgroundColor: value > min 
                    ? AppTheme.primaryPurple.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                foregroundColor: value > min ? AppTheme.primaryPurple : Colors.grey,
              ),
            ),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ step,
                label: '$value $unit',
                onChanged: (newValue) => onChanged(newValue.round()),
                activeColor: AppTheme.primaryPurple,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: value < max ? () => onChanged(value + step) : null,
              style: IconButton.styleFrom(
                backgroundColor: value < max 
                    ? AppTheme.primaryPurple.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                foregroundColor: value < max ? AppTheme.primaryPurple : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataResetCard() {
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reset Progress Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If your progress data seems incorrect (like showing hundreds of cards when you only studied a few), you can reset all progress data to start fresh.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showResetConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reset All Progress Data',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress Data'),
        content: const Text(
          'This will permanently delete all your progress data including:\n\n'
          '• Daily progress\n'
          '• Weekly progress\n'
          '• Deck progress\n'
          '• Goal achievements\n'
          '• Study streaks\n\n'
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetProgressData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetProgressData() async {
    try {
      setState(() => _isSaving = true);
      
      await DataResetHelper.resetAllProgressData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress data reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent to refresh progress dashboard
        if (widget.onDataChanged != null) {
          widget.onDataChanged!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These goals help track your learning progress. Progress is only counted when you complete challenges.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
