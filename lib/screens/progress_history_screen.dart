import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/progress_tracking_service.dart';
import '../services/goal_tracking_service.dart';

class ProgressHistoryScreen extends StatefulWidget {
  const ProgressHistoryScreen({super.key});

  @override
  State<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends State<ProgressHistoryScreen>
    with TickerProviderStateMixin {
  final ProgressTrackingService _progressService = ProgressTrackingService();
  final GoalTrackingService _goalService = GoalTrackingService();
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // Daily history data
  List<DailyProgressHistory> _dailyHistory = [];
  
  // Weekly history data
  List<WeeklyProgressHistory> _weeklyHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load daily history (last 7 days)
      _dailyHistory = await _progressService.getDailyHistory(7);
      
      // Load weekly history (last 4 weeks)
      _weeklyHistory = await _progressService.getWeeklyHistory(4);
      
    } catch (e) {
      print('Error loading history data: $e');
    } finally {
      setState(() => _isLoading = false);
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
          'Progress History',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryPurple,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyHistory(),
                _buildWeeklyHistory(),
              ],
            ),
    );
  }

  Widget _buildDailyHistory() {
    if (_dailyHistory.isEmpty) {
      return _buildEmptyState('No daily progress history available');
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _dailyHistory.length,
        itemBuilder: (context, index) {
          final day = _dailyHistory[index];
          return _buildDailyHistoryCard(day);
        },
      ),
    );
  }

  Widget _buildWeeklyHistory() {
    if (_weeklyHistory.isEmpty) {
      return _buildEmptyState('No weekly progress history available');
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _weeklyHistory.length,
        itemBuilder: (context, index) {
          final week = _weeklyHistory[index];
          return _buildWeeklyHistoryCard(week);
        },
      ),
    );
  }

  Widget _buildDailyHistoryCard(DailyProgressHistory day) {
    final isToday = _isToday(day.date);
    final isYesterday = _isYesterday(day.date);
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = _formatDate(day.date);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppTheme.primaryPurple.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: isToday ? AppTheme.primaryPurple : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppTheme.primaryPurple : AppTheme.textPrimary,
                        ),
                      ),
                      if (!isToday && !isYesterday)
                        Text(
                          _formatDateFull(day.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (day.studyStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: AppTheme.primaryPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${day.studyStreak}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress stats
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat(
                    'Study Time',
                    '${day.duration} min',
                    day.duration,
                    day.dailyStudyGoal,
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressStat(
                    'Cards',
                    '${day.cardsStudied}',
                    day.cardsStudied,
                    day.dailyCardGoal,
                    Icons.style,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Accuracy
            if (day.cardsStudied > 0)
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: day.accuracy >= 80 ? Colors.green : 
                           day.accuracy >= 60 ? Colors.orange : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Accuracy: ${day.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: day.accuracy >= 80 ? Colors.green : 
                             day.accuracy >= 60 ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHistoryCard(WeeklyProgressHistory week) {
    final isThisWeek = _isThisWeek(week.weekStart);
    final isLastWeek = _isLastWeek(week.weekStart);
    
    String weekLabel;
    if (isThisWeek) {
      weekLabel = 'This Week';
    } else if (isLastWeek) {
      weekLabel = 'Last Week';
    } else {
      weekLabel = 'Week of ${_formatDate(week.weekStart)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isThisWeek 
                        ? AppTheme.primaryPurple.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_view_week,
                    color: isThisWeek ? AppTheme.primaryPurple : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isThisWeek ? AppTheme.primaryPurple : AppTheme.textPrimary,
                        ),
                      ),
                      if (!isThisWeek && !isLastWeek)
                        Text(
                          '${_formatDate(week.weekStart)} - ${_formatDate(week.weekStart.add(const Duration(days: 6)))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (week.studyDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${week.studyDays} days',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress stats
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat(
                    'Study Time',
                    '${week.duration} min',
                    week.duration,
                    week.weeklyStudyGoal,
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressStat(
                    'Cards',
                    '${week.cardsStudied}',
                    week.cardsStudied,
                    week.weeklyCardGoal,
                    Icons.style,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Average accuracy
            if (week.cardsStudied > 0)
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: week.accuracy >= 80 ? Colors.green : 
                           week.accuracy >= 60 ? Colors.orange : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Avg Accuracy: ${week.accuracy.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: week.accuracy >= 80 ? Colors.green : 
                             week.accuracy >= 60 ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(
    String label,
    String value,
    int current,
    int goal,
    IconData icon,
    Color color,
  ) {
    final percentage = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
        const SizedBox(height: 2),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}% of goal',
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  bool _isThisWeek(DateTime weekStart) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.year == thisWeekStart.year && 
           weekStart.month == thisWeekStart.month && 
           weekStart.day == thisWeekStart.day;
  }

  bool _isLastWeek(DateTime weekStart) {
    final now = DateTime.now();
    final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
    return weekStart.year == lastWeekStart.year && 
           weekStart.month == lastWeekStart.month && 
           weekStart.day == lastWeekStart.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatDateFull(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

