import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import 'login_history_screen.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  bool _isLoading = false;
  bool _loginNotifications = true;
  bool _suspiciousActivityAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load security settings using security service
      final loginNotifications = await _securityService.hasLoginNotificationsEnabled();
      final suspiciousActivityAlerts = await _securityService.hasSuspiciousActivityAlertsEnabled();
      
      setState(() {
        _loginNotifications = loginNotifications;
        _suspiciousActivityAlerts = suspiciousActivityAlerts;
      });
    } catch (e) {
      print('Error loading security settings: $e');
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
          'Account Security',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Status Card
                  _buildSecurityStatusCard(),
                  const SizedBox(height: 24),
                  
                  // Security Notifications
                  _buildSectionTitle('Security Notifications'),
                  const SizedBox(height: 16),
                  
                  _buildSecurityItem(
                    icon: Icons.login,
                    title: 'Login Notifications',
                    subtitle: 'Get notified when someone logs into your account',
                    trailing: Switch(
                      value: _loginNotifications,
                      onChanged: (value) => _updateSecuritySetting('loginNotifications', value),
                      activeColor: AppTheme.primaryPurple,
                    ),
                  ),
                  
                  _buildSecurityItem(
                    icon: Icons.warning,
                    title: 'Suspicious Activity Alerts',
                    subtitle: 'Get alerts for unusual login attempts',
                    trailing: Switch(
                      value: _suspiciousActivityAlerts,
                      onChanged: (value) => _updateSecuritySetting('suspiciousActivityAlerts', value),
                      activeColor: AppTheme.primaryPurple,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Security Actions
                  _buildSectionTitle('Security Actions'),
                  const SizedBox(height: 16),
                  
                  _buildSecurityItem(
                    icon: Icons.history,
                    title: 'Login History',
                    subtitle: 'View recent login attempts and sessions',
                    onTap: _showLoginHistory,
                  ),
                  
                  _buildSecurityItem(
                    icon: Icons.lock_reset,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: _changePassword,
                  ),
                  
                  _buildSecurityItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    onTap: _deleteAccount,
                    isDestructive: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reset Security Settings
                  _buildSectionTitle('Reset Settings'),
                  const SizedBox(height: 16),
                  
                  _buildSecurityItem(
                    icon: Icons.restore,
                    title: 'Reset Security Settings',
                    subtitle: 'Reset all security settings to default',
                    onTap: _resetSecuritySettings,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return FutureBuilder<int>(
      future: _securityService.getSecurityScore(),
      builder: (context, snapshot) {
        final score = snapshot.data ?? 0;
        final status = _getSecurityStatus(score);
        final color = _getSecurityColor(score);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Security Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.1)
                : AppTheme.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppTheme.primaryPurple,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ) : null),
        onTap: onTap,
      ),
    );
  }

  Color _getSecurityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getSecurityStatus(int score) {
    if (score >= 80) return 'Excellent security! Your account is well protected.';
    if (score >= 60) return 'Good security. Consider enabling more features.';
    return 'Weak security. Please enable additional security features.';
  }

  Future<void> _updateSecuritySetting(String key, dynamic value) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserProfile(additionalData: {key: value});
        setState(() {
          if (key == 'loginNotifications') {
            _loginNotifications = value;
          } else if (key == 'suspiciousActivityAlerts') {
            _suspiciousActivityAlerts = value;
          }
        });
      }
    } catch (e) {
      print('Error updating security setting: $e');
    }
  }

  void _showLoginHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginHistoryScreen(),
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'Password change functionality will be implemented in a future update.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Reset Security Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to reset all security settings to default? This will reset all notification preferences.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmResetSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetSettings() async {
    try {
      await _updateSecuritySetting('loginNotifications', true);
      await _updateSecuritySetting('suspiciousActivityAlerts', true);
      
      setState(() {
        _loginNotifications = true;
        _suspiciousActivityAlerts = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings reset to default'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}