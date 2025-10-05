import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/privacy_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final AuthService _authService = AuthService();
  final PrivacyService _privacyService = PrivacyService();
  bool _isLoading = true;
  bool _isSaving = false;

  // Profile Privacy Settings
  bool _profilePublic = false;
  bool _showStudyProgress = true;
  bool _showAchievements = true;
  bool _showStreaks = true;
  bool _showPoints = true;

  // Data Sharing Settings
  bool _shareAnalytics = true;
  bool _shareUsageData = false;
  bool _shareCrashReports = true;
  bool _sharePerformanceData = true;

  // Social Privacy Settings
  bool _allowFriendRequests = true;
  bool _showOnlineStatus = true;
  bool _allowLeaderboard = true;
  bool _allowChallenges = true;

  // Data Collection Settings
  bool _collectStudyData = true;
  bool _collectDeviceInfo = true;
  bool _collectLocationData = false;
  bool _collectUsagePatterns = true;

  // Data Retention Settings
  int _dataRetentionPeriod = 365; // days
  bool _autoDeleteOldData = true;
  bool _allowDataExport = true;
  bool _allowDataDeletion = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _privacyService.getPrivacySettings();
      if (settings != null) {
        // Profile Privacy Settings
        _profilePublic = settings.profilePublic;
        _showStudyProgress = settings.showStudyProgress;
        _showAchievements = settings.showAchievements;
        _showStreaks = settings.showStreaks;
        _showPoints = settings.showPoints;
        
        // Data Sharing Settings
        _shareAnalytics = settings.shareAnalytics;
        _shareUsageData = settings.shareUsageData;
        _shareCrashReports = settings.shareCrashReports;
        _sharePerformanceData = settings.sharePerformanceData;
        
        // Social Privacy Settings
        _allowFriendRequests = settings.allowFriendRequests;
        _showOnlineStatus = settings.showOnlineStatus;
        _allowLeaderboard = settings.allowLeaderboard;
        _allowChallenges = settings.allowChallenges;
        
        // Data Collection Settings
        _collectStudyData = settings.collectStudyData;
        _collectDeviceInfo = settings.collectDeviceInfo;
        _collectLocationData = settings.collectLocationData;
        _collectUsagePatterns = settings.collectUsagePatterns;
        
        // Data Retention Settings
        _dataRetentionPeriod = settings.dataRetentionPeriod;
        _autoDeleteOldData = settings.autoDeleteOldData;
        _allowDataExport = settings.allowDataExport;
        _allowDataDeletion = settings.allowDataDeletion;
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final settings = PrivacySettings(
        profilePublic: _profilePublic,
        showStudyProgress: _showStudyProgress,
        showAchievements: _showAchievements,
        showStreaks: _showStreaks,
        showPoints: _showPoints,
        shareAnalytics: _shareAnalytics,
        shareUsageData: _shareUsageData,
        shareCrashReports: _shareCrashReports,
        sharePerformanceData: _sharePerformanceData,
        allowFriendRequests: _allowFriendRequests,
        showOnlineStatus: _showOnlineStatus,
        allowLeaderboard: _allowLeaderboard,
        allowChallenges: _allowChallenges,
        collectStudyData: _collectStudyData,
        collectDeviceInfo: _collectDeviceInfo,
        collectLocationData: _collectLocationData,
        collectUsagePatterns: _collectUsagePatterns,
        dataRetentionPeriod: _dataRetentionPeriod,
        autoDeleteOldData: _autoDeleteOldData,
        allowDataExport: _allowDataExport,
        allowDataDeletion: _allowDataDeletion,
      );
      
      await _privacyService.savePrivacySettings(settings);
        
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved successfully!'),
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

  Future<void> _deleteAllData() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete All Data',
      content: 'Are you sure you want to delete all your data? This action cannot be undone.',
      confirmText: 'Delete All Data',
    );

    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Use AuthService's deleteAccount method which handles all data deletion
        await _authService.deleteAccount();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          'Privacy Settings',
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
                  // Profile Privacy Section
                  _buildSectionCard(
                    title: 'Profile Privacy',
                    icon: Icons.person,
                    children: [
                      SwitchListTile(
                        title: const Text('Public Profile'),
                        subtitle: const Text('Allow others to view your profile'),
                        value: _profilePublic,
                        onChanged: (value) {
                          setState(() => _profilePublic = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      if (_profilePublic) ...[
                        SwitchListTile(
                          title: const Text('Show Study Progress'),
                          subtitle: const Text('Display your study progress to others'),
                          value: _showStudyProgress,
                          onChanged: (value) {
                            setState(() => _showStudyProgress = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                        SwitchListTile(
                          title: const Text('Show Achievements'),
                          subtitle: const Text('Display your achievements to others'),
                          value: _showAchievements,
                          onChanged: (value) {
                            setState(() => _showAchievements = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                        SwitchListTile(
                          title: const Text('Show Streaks'),
                          subtitle: const Text('Display your study streaks to others'),
                          value: _showStreaks,
                          onChanged: (value) {
                            setState(() => _showStreaks = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                        SwitchListTile(
                          title: const Text('Show Points'),
                          subtitle: const Text('Display your points to others'),
                          value: _showPoints,
                          onChanged: (value) {
                            setState(() => _showPoints = value);
                          },
                          activeColor: AppTheme.primaryPurple,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Sharing Section
                  _buildSectionCard(
                    title: 'Data Sharing',
                    icon: Icons.share,
                    children: [
                      SwitchListTile(
                        title: const Text('Share Analytics'),
                        subtitle: const Text('Help improve the app by sharing anonymous usage data'),
                        value: _shareAnalytics,
                        onChanged: (value) {
                          setState(() => _shareAnalytics = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Share Usage Data'),
                        subtitle: const Text('Share detailed usage patterns for app improvement'),
                        value: _shareUsageData,
                        onChanged: (value) {
                          setState(() => _shareUsageData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Share Crash Reports'),
                        subtitle: const Text('Automatically send crash reports to help fix bugs'),
                        value: _shareCrashReports,
                        onChanged: (value) {
                          setState(() => _shareCrashReports = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Share Performance Data'),
                        subtitle: const Text('Share app performance data for optimization'),
                        value: _sharePerformanceData,
                        onChanged: (value) {
                          setState(() => _sharePerformanceData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Social Privacy Section
                  _buildSectionCard(
                    title: 'Social Features',
                    icon: Icons.people,
                    children: [
                      SwitchListTile(
                        title: const Text('Allow Friend Requests'),
                        subtitle: const Text('Let other users send you friend requests'),
                        value: _allowFriendRequests,
                        onChanged: (value) {
                          setState(() => _allowFriendRequests = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Show Online Status'),
                        subtitle: const Text('Display when you\'re online to friends'),
                        value: _showOnlineStatus,
                        onChanged: (value) {
                          setState(() => _showOnlineStatus = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Allow Leaderboard'),
                        subtitle: const Text('Include your progress in leaderboards'),
                        value: _allowLeaderboard,
                        onChanged: (value) {
                          setState(() => _allowLeaderboard = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Allow Challenges'),
                        subtitle: const Text('Let others challenge you to study competitions'),
                        value: _allowChallenges,
                        onChanged: (value) {
                          setState(() => _allowChallenges = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Collection Section
                  _buildSectionCard(
                    title: 'Data Collection',
                    icon: Icons.data_usage,
                    children: [
                      SwitchListTile(
                        title: const Text('Collect Study Data'),
                        subtitle: const Text('Track your study sessions and progress'),
                        value: _collectStudyData,
                        onChanged: (value) {
                          setState(() => _collectStudyData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Collect Device Info'),
                        subtitle: const Text('Collect device information for app optimization'),
                        value: _collectDeviceInfo,
                        onChanged: (value) {
                          setState(() => _collectDeviceInfo = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Collect Location Data'),
                        subtitle: const Text('Collect location data for personalized features'),
                        value: _collectLocationData,
                        onChanged: (value) {
                          setState(() => _collectLocationData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Collect Usage Patterns'),
                        subtitle: const Text('Track how you use the app for improvements'),
                        value: _collectUsagePatterns,
                        onChanged: (value) {
                          setState(() => _collectUsagePatterns = value);
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
                        subtitle: Text('$_dataRetentionPeriod days'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _dataRetentionPeriod > 30
                                  ? () => setState(() => _dataRetentionPeriod -= 30)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _dataRetentionPeriod < 1095
                                  ? () => setState(() => _dataRetentionPeriod += 30)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Auto Delete Old Data'),
                        subtitle: const Text('Automatically delete data older than retention period'),
                        value: _autoDeleteOldData,
                        onChanged: (value) {
                          setState(() => _autoDeleteOldData = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Allow Data Export'),
                        subtitle: const Text('Allow exporting your data'),
                        value: _allowDataExport,
                        onChanged: (value) {
                          setState(() => _allowDataExport = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                      SwitchListTile(
                        title: const Text('Allow Data Deletion'),
                        subtitle: const Text('Allow deleting your data'),
                        value: _allowDataDeletion,
                        onChanged: (value) {
                          setState(() => _allowDataDeletion = value);
                        },
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Data Management Section
                  _buildSectionCard(
                    title: 'Data Management',
                    icon: Icons.delete_forever,
                    children: [
                      ListTile(
                        title: const Text('Delete All Data'),
                        subtitle: const Text('Permanently delete all your data from the app'),
                        leading: const Icon(Icons.warning, color: Colors.red),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _deleteAllData,
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
