import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;

  // General Notification Settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ledEnabled = true;

  // Study Reminder Notifications
  bool _studyReminders = true;
  bool _goalReminders = true;
  bool _streakReminders = true;
  bool _breakReminders = true;

  // Achievement Notifications
  bool _achievementNotifications = true;
  bool _levelUpNotifications = true;
  bool _milestoneNotifications = true;
  bool _badgeNotifications = true;

  // Progress Notifications
  bool _progressUpdates = true;
  bool _weeklyReports = true;
  bool _monthlyReports = false;
  bool _goalAchievements = true;

  // Social Notifications
  bool _friendRequests = true;
  bool _friendActivity = false;
  bool _leaderboardUpdates = true;
  bool _challengeInvites = true;

  // Quiet Hours
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('notifications')
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          
          // General Notification Settings
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _soundEnabled = data['soundEnabled'] ?? true;
          _vibrationEnabled = data['vibrationEnabled'] ?? true;
          _ledEnabled = data['ledEnabled'] ?? true;
          
          // Study Reminder Notifications
          _studyReminders = data['studyReminders'] ?? true;
          _goalReminders = data['goalReminders'] ?? true;
          _streakReminders = data['streakReminders'] ?? true;
          _breakReminders = data['breakReminders'] ?? true;
          
          // Achievement Notifications
          _achievementNotifications = data['achievementNotifications'] ?? true;
          _levelUpNotifications = data['levelUpNotifications'] ?? true;
          _milestoneNotifications = data['milestoneNotifications'] ?? true;
          _badgeNotifications = data['badgeNotifications'] ?? true;
          
          // Progress Notifications
          _progressUpdates = data['progressUpdates'] ?? true;
          _weeklyReports = data['weeklyReports'] ?? true;
          _monthlyReports = data['monthlyReports'] ?? false;
          _goalAchievements = data['goalAchievements'] ?? true;
          
          // Social Notifications
          _friendRequests = data['friendRequests'] ?? true;
          _friendActivity = data['friendActivity'] ?? false;
          _leaderboardUpdates = data['leaderboardUpdates'] ?? true;
          _challengeInvites = data['challengeInvites'] ?? true;
          
          // Quiet Hours
          _quietHoursEnabled = data['quietHoursEnabled'] ?? false;
          final quietStart = data['quietHoursStart'];
          if (quietStart != null) {
            _quietHoursStart = TimeOfDay(
              hour: quietStart['hour'] ?? 22,
              minute: quietStart['minute'] ?? 0,
            );
          }
          final quietEnd = data['quietHoursEnd'];
          if (quietEnd != null) {
            _quietHoursEnd = TimeOfDay(
              hour: quietEnd['hour'] ?? 8,
              minute: quietEnd['minute'] ?? 0,
            );
          }
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('notifications')
            .set({
          // General Notification Settings
          'notificationsEnabled': _notificationsEnabled,
          'soundEnabled': _soundEnabled,
          'vibrationEnabled': _vibrationEnabled,
          'ledEnabled': _ledEnabled,
          
          // Study Reminder Notifications
          'studyReminders': _studyReminders,
          'goalReminders': _goalReminders,
          'streakReminders': _streakReminders,
          'breakReminders': _breakReminders,
          
          // Achievement Notifications
          'achievementNotifications': _achievementNotifications,
          'levelUpNotifications': _levelUpNotifications,
          'milestoneNotifications': _milestoneNotifications,
          'badgeNotifications': _badgeNotifications,
          
          // Progress Notifications
          'progressUpdates': _progressUpdates,
          'weeklyReports': _weeklyReports,
          'monthlyReports': _monthlyReports,
          'goalAchievements': _goalAchievements,
          
          // Social Notifications
          'friendRequests': _friendRequests,
          'friendActivity': _friendActivity,
          'leaderboardUpdates': _leaderboardUpdates,
          'challengeInvites': _challengeInvites,
          
          // Quiet Hours
          'quietHoursEnabled': _quietHoursEnabled,
          'quietHoursStart': {
            'hour': _quietHoursStart.hour,
            'minute': _quietHoursStart.minute,
          },
          'quietHoursEnd': {
            'hour': _quietHoursEnd.hour,
            'minute': _quietHoursEnd.minute,
          },
          
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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

  Future<void> _selectQuietHoursStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _quietHoursStart,
    );
    
    if (picked != null && picked != _quietHoursStart) {
      setState(() => _quietHoursStart = picked);
    }
  }

  Future<void> _selectQuietHoursEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _quietHoursEnd,
    );
    
    if (picked != null && picked != _quietHoursEnd) {
      setState(() => _quietHoursEnd = picked);
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
          'Notification Settings',
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
                  // General Settings Section
                  _buildSectionCard(
                    title: 'General Settings',
                    icon: Icons.settings,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Notifications'),
                        subtitle: const Text('Allow all notifications from the app'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      if (_notificationsEnabled) ...[
                        SwitchListTile(
                          title: const Text('Sound'),
                          subtitle: const Text('Play sound for notifications'),
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() => _soundEnabled = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                        SwitchListTile(
                          title: const Text('Vibration'),
                          subtitle: const Text('Vibrate for notifications'),
                          value: _vibrationEnabled,
                          onChanged: (value) {
                            setState(() => _vibrationEnabled = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                        SwitchListTile(
                          title: const Text('LED Light'),
                          subtitle: const Text('Use LED light for notifications'),
                          value: _ledEnabled,
                          onChanged: (value) {
                            setState(() => _ledEnabled = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Study Reminders Section
                  _buildSectionCard(
                    title: 'Study Reminders',
                    icon: Icons.school,
                    children: [
                      SwitchListTile(
                        title: const Text('Study Reminders'),
                        subtitle: const Text('Remind me to study at scheduled times'),
                        value: _studyReminders,
                        onChanged: (value) {
                          setState(() => _studyReminders = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Goal Reminders'),
                        subtitle: const Text('Remind me about daily and weekly goals'),
                        value: _goalReminders,
                        onChanged: (value) {
                          setState(() => _goalReminders = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Streak Reminders'),
                        subtitle: const Text('Remind me to maintain study streaks'),
                        value: _streakReminders,
                        onChanged: (value) {
                          setState(() => _streakReminders = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Break Reminders'),
                        subtitle: const Text('Remind me to take breaks during study sessions'),
                        value: _breakReminders,
                        onChanged: (value) {
                          setState(() => _breakReminders = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Achievement Notifications Section
                  _buildSectionCard(
                    title: 'Achievements',
                    icon: Icons.emoji_events,
                    children: [
                      SwitchListTile(
                        title: const Text('Achievement Notifications'),
                        subtitle: const Text('Notify when earning achievements'),
                        value: _achievementNotifications,
                        onChanged: (value) {
                          setState(() => _achievementNotifications = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Level Up Notifications'),
                        subtitle: const Text('Notify when leveling up'),
                        value: _levelUpNotifications,
                        onChanged: (value) {
                          setState(() => _levelUpNotifications = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Milestone Notifications'),
                        subtitle: const Text('Notify when reaching milestones'),
                        value: _milestoneNotifications,
                        onChanged: (value) {
                          setState(() => _milestoneNotifications = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Badge Notifications'),
                        subtitle: const Text('Notify when earning badges'),
                        value: _badgeNotifications,
                        onChanged: (value) {
                          setState(() => _badgeNotifications = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Progress Notifications Section
                  _buildSectionCard(
                    title: 'Progress Updates',
                    icon: Icons.trending_up,
                    children: [
                      SwitchListTile(
                        title: const Text('Progress Updates'),
                        subtitle: const Text('Notify about progress changes'),
                        value: _progressUpdates,
                        onChanged: (value) {
                          setState(() => _progressUpdates = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Weekly Reports'),
                        subtitle: const Text('Send weekly progress reports'),
                        value: _weeklyReports,
                        onChanged: (value) {
                          setState(() => _weeklyReports = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Monthly Reports'),
                        subtitle: const Text('Send monthly progress reports'),
                        value: _monthlyReports,
                        onChanged: (value) {
                          setState(() => _monthlyReports = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Goal Achievements'),
                        subtitle: const Text('Notify when achieving goals'),
                        value: _goalAchievements,
                        onChanged: (value) {
                          setState(() => _goalAchievements = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social Notifications Section
                  _buildSectionCard(
                    title: 'Social Features',
                    icon: Icons.people,
                    children: [
                      SwitchListTile(
                        title: const Text('Friend Requests'),
                        subtitle: const Text('Notify about friend requests'),
                        value: _friendRequests,
                        onChanged: (value) {
                          setState(() => _friendRequests = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Friend Activity'),
                        subtitle: const Text('Notify about friends\' study activity'),
                        value: _friendActivity,
                        onChanged: (value) {
                          setState(() => _friendActivity = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Leaderboard Updates'),
                        subtitle: const Text('Notify about leaderboard changes'),
                        value: _leaderboardUpdates,
                        onChanged: (value) {
                          setState(() => _leaderboardUpdates = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Challenge Invites'),
                        subtitle: const Text('Notify about challenge invitations'),
                        value: _challengeInvites,
                        onChanged: (value) {
                          setState(() => _challengeInvites = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quiet Hours Section
                  _buildSectionCard(
                    title: 'Quiet Hours',
                    icon: Icons.bedtime,
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Quiet Hours'),
                        subtitle: const Text('Disable notifications during specified hours'),
                        value: _quietHoursEnabled,
                        onChanged: (value) {
                          setState(() => _quietHoursEnabled = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      if (_quietHoursEnabled) ...[
                        ListTile(
                          title: const Text('Quiet Hours Start'),
                          subtitle: Text(_quietHoursStart.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: _selectQuietHoursStart,
                        ),
                        ListTile(
                          title: const Text('Quiet Hours End'),
                          subtitle: Text(_quietHoursEnd.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: _selectQuietHoursEnd,
                        ),
                      ],
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
