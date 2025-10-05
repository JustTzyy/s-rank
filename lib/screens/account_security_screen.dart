import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import 'login_history_screen.dart';
import 'active_sessions_screen.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  bool _isLoading = false;
  bool _twoFactorEnabled = false;
  bool _loginNotifications = true;
  bool _suspiciousActivityAlerts = true;
  String _backupCode = '';

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Load security settings using security service
      final twoFactorEnabled = await _securityService.isTwoFactorEnabled();
      final loginNotifications = await _securityService.hasLoginNotificationsEnabled();
      final suspiciousActivityAlerts = await _securityService.hasSuspiciousActivityAlertsEnabled();
      
      setState(() {
        _twoFactorEnabled = twoFactorEnabled;
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
                  
                  // Two-Factor Authentication
                  _buildSectionTitle('Two-Factor Authentication'),
                  const SizedBox(height: 16),
                  
                  _buildSecurityItem(
                    icon: Icons.security,
                    title: 'Two-Factor Authentication',
                    subtitle: _twoFactorEnabled 
                        ? 'Enabled - Your account is protected' 
                        : 'Add an extra layer of security',
                    trailing: Switch(
                      value: _twoFactorEnabled,
                      onChanged: _toggleTwoFactor,
                      activeColor: AppTheme.primaryPurple,
                    ),
                    onTap: _showTwoFactorDialog,
                  ),
                  
                  if (_twoFactorEnabled) ...[
                    const SizedBox(height: 12),
                    _buildSecurityItem(
                      icon: Icons.backup,
                      title: 'Backup Codes',
                      subtitle: 'Generate backup codes for account recovery',
                      onTap: _generateBackupCodes,
                    ),
                  ],
                  
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
                    subtitle: 'Get alerts for unusual account activity',
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
                    icon: Icons.devices,
                    title: 'Active Sessions',
                    subtitle: 'Manage devices logged into your account',
                    onTap: _showActiveSessions,
                  ),
                  
                  _buildSecurityItem(
                    icon: Icons.history,
                    title: 'Login History',
                    subtitle: 'View recent login attempts and locations',
                    onTap: _showLoginHistory,
                  ),
                  
                  _buildSecurityItem(
                    icon: Icons.lock_reset,
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
      future: _calculateSecurityScore(),
      builder: (context, snapshot) {
        final securityScore = snapshot.data ?? 0;
        final statusColor = securityScore >= 80 
            ? Colors.green 
            : securityScore >= 60 
                ? Colors.orange 
                : Colors.red;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  securityScore >= 80 ? Icons.security : Icons.warning,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Score: $securityScore%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSecurityStatusText(securityScore),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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

  Future<int> _calculateSecurityScore() async {
    return await _securityService.getSecurityScore();
  }

  String _getSecurityStatusText(int score) {
    if (score >= 80) return 'Excellent security! Your account is well protected.';
    if (score >= 60) return 'Good security. Consider enabling more features.';
    return 'Weak security. Please enable additional security features.';
  }

  void _toggleTwoFactor(bool value) {
    if (value) {
      _showTwoFactorSetupDialog();
    } else {
      _showDisableTwoFactorDialog();
    }
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          _twoFactorEnabled 
              ? 'Two-factor authentication is currently enabled. This adds an extra layer of security to your account.'
              : 'Two-factor authentication adds an extra layer of security by requiring a second form of verification when logging in.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!_twoFactorEnabled)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTwoFactorSetupDialog();
              },
              child: const Text('Enable'),
            ),
        ],
      ),
    );
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Enable Two-Factor Authentication',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'Two-factor authentication will be enabled for your account. You will need to enter a verification code from your authenticator app when logging in.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _enableTwoFactor();
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showDisableTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Disable Two-Factor Authentication',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? This will make your account less secure.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _disableTwoFactor();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableTwoFactor() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate 2FA setup (in real app, you'd integrate with Firebase Auth 2FA)
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _twoFactorEnabled = true;
        _backupCode = _generateBackupCode();
      });
      
      await _updateSecuritySetting('twoFactorEnabled', true);
      
      if (mounted) {
        _showBackupCodeDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication enabled successfully!'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling 2FA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableTwoFactor() async {
    setState(() => _isLoading = true);
    
    try {
      await _updateSecuritySetting('twoFactorEnabled', false);
      
      setState(() {
        _twoFactorEnabled = false;
        _backupCode = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling 2FA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBackupCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Backup Code Generated',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save this backup code in a safe place. You can use it to access your account if you lose your authenticator device.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _backupCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _backupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup code copied to clipboard'),
                          backgroundColor: AppTheme.primaryPurple,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I\'ve Saved It'),
          ),
        ],
      ),
    );
  }

  void _generateBackupCodes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Generate New Backup Codes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'This will generate new backup codes and invalidate your old ones. Make sure to save the new codes in a safe place.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _backupCode = _generateBackupCode();
              });
              _showBackupCodeDialog();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  String _generateBackupCode() {
    final codes = _securityService.generateBackupCodes(count: 1);
    return codes.isNotEmpty ? codes.first : '';
  }

  Future<void> _updateSecuritySetting(String key, dynamic value) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserProfile(additionalData: {key: value});
      }
    } catch (e) {
      print('Error updating security setting: $e');
    }
  }

  void _showActiveSessions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActiveSessionsScreen(),
      ),
    );
  }

  void _showLoginHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginHistoryScreen(),
      ),
    );
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
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Are you sure you want to reset all security settings to default? This will disable two-factor authentication and reset all notification preferences.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performSecurityReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSecurityReset() async {
    setState(() => _isLoading = true);
    
    try {
      await _updateSecuritySetting('twoFactorEnabled', false);
      await _updateSecuritySetting('loginNotifications', true);
      await _updateSecuritySetting('suspiciousActivityAlerts', true);
      
      setState(() {
        _twoFactorEnabled = false;
        _loginNotifications = true;
        _suspiciousActivityAlerts = true;
        _backupCode = '';
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
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
