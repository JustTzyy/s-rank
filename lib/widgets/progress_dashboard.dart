import 'package:flutter/material.dart';
import '../services/progress_tracking_service.dart';
import '../theme/app_theme.dart';
import '../screens/progress_history_screen.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => ProgressDashboardState();
}

class ProgressDashboardState extends State<ProgressDashboard> {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  
  GoalProgress? _goalProgress;
  int _studyStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  // Method to refresh progress data (can be called from parent)
  Future<void> refreshProgress() async {
    await _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      // Progress tracking is always enabled
      final goalProgress = await _progressService.getGoalProgress();
      final studyStreak = await _progressService.getStudyStreak();
      
      setState(() {
        _goalProgress = goalProgress;
        _studyStreak = studyStreak;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Progress dashboard is always shown

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProgressHistoryScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_studyStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_studyStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_goalProgress != null) ...[
            // Daily Study Time Progress
            _buildProgressItem(
              'Study Time',
              '${_goalProgress!.dailyStudyProgress} / ${_goalProgress!.dailyStudyGoal} min',
              _goalProgress!.dailyStudyProgressPercentage,
              Icons.timer,
            ),
            const SizedBox(height: 12),
            
            // Daily Cards Progress
            _buildProgressItem(
              'Cards Studied',
              '${_goalProgress!.dailyCardProgress} / ${_goalProgress!.dailyCardGoal}',
              _goalProgress!.dailyCardProgressPercentage,
              Icons.style,
            ),
            const SizedBox(height: 12),
            
            // Weekly Progress
            Row(
              children: [
                Expanded(
                  child: _buildWeeklyProgressItem(
                    'Weekly Study',
                    '${_goalProgress!.weeklyStudyProgress} / ${_goalProgress!.weeklyStudyGoal} min',
                    _goalProgress!.weeklyStudyProgressPercentage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeeklyProgressItem(
                    'Weekly Cards',
                    '${_goalProgress!.weeklyCardProgress} / ${_goalProgress!.weeklyCardGoal}',
                    _goalProgress!.weeklyCardProgressPercentage,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildProgressItem(String title, String subtitle, double progress, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : AppTheme.primaryPurple,
          ),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressItem(String title, String subtitle, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : AppTheme.primaryPurple,
          ),
          minHeight: 4,
        ),
      ],
    );
  }
}
