import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<LoginAttempt> _loginHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLoginHistory();
  }

  Future<void> _loadLoginHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load login history from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('loginHistory')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
        
        _loginHistory = snapshot.docs.map((doc) {
          final data = doc.data();
          return LoginAttempt(
            id: doc.id,
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            deviceInfo: data['deviceInfo'] ?? 'Unknown Device',
            location: data['location'] ?? 'Unknown Location',
            ipAddress: data['ipAddress'] ?? 'Unknown IP',
            userAgent: data['userAgent'] ?? 'Unknown Browser',
            isSuccessful: data['isSuccessful'] ?? true,
            failureReason: data['failureReason'],
          );
        }).toList();
      }
    } catch (e) {
      print('Error loading login history: $e');
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
          'Login History',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.primaryPurple,
            ),
            onPressed: _loadLoginHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loginHistory.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    
                    // Login History List
                    Expanded(
                      child: _buildLoginHistoryList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Login History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your login attempts will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final successfulLogins = _loginHistory.where((login) => login.isSuccessful).length;
    final failedLogins = _loginHistory.where((login) => !login.isSuccessful).length;
    final uniqueDevices = _loginHistory.map((login) => login.deviceInfo).toSet().length;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Logins',
                '${_loginHistory.length}',
                Icons.login,
                AppTheme.primaryPurple,
              ),
              _buildSummaryItem(
                'Successful',
                '$successfulLogins',
                Icons.check_circle,
                Colors.green,
              ),
              _buildSummaryItem(
                'Failed',
                '$failedLogins',
                Icons.cancel,
                Colors.red,
              ),
              _buildSummaryItem(
                'Devices',
                '$uniqueDevices',
                Icons.devices,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _loginHistory.length,
      itemBuilder: (context, index) {
        final login = _loginHistory[index];
        return _buildLoginHistoryItem(login);
      },
    );
  }

  Widget _buildLoginHistoryItem(LoginAttempt login) {
    final isRecent = DateTime.now().difference(login.timestamp).inDays < 7;
    final statusColor = login.isSuccessful ? Colors.green : Colors.red;
    final statusIcon = login.isSuccessful ? Icons.check_circle : Icons.cancel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isRecent ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)) : null,
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
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          login.deviceInfo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              login.location,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(login.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            if (!login.isSuccessful && login.failureReason != null) ...[
              const SizedBox(height: 2),
              Text(
                'Failed: ${login.failureReason}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              login.ipAddress,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            if (isRecent) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showLoginDetails(login),
      ),
    );
  }

  void _showLoginDetails(LoginAttempt login) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              login.isSuccessful ? Icons.check_circle : Icons.cancel,
              color: login.isSuccessful ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Login Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Device', login.deviceInfo),
            _buildDetailRow('Location', login.location),
            _buildDetailRow('IP Address', login.ipAddress),
            _buildDetailRow('Browser', login.userAgent),
            _buildDetailRow('Time', _formatDetailedTimestamp(login.timestamp)),
            _buildDetailRow('Status', login.isSuccessful ? 'Successful' : 'Failed'),
            if (!login.isSuccessful && login.failureReason != null)
              _buildDetailRow('Reason', login.failureReason!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDetailedTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class LoginAttempt {
  final String id;
  final DateTime timestamp;
  final String deviceInfo;
  final String location;
  final String ipAddress;
  final String userAgent;
  final bool isSuccessful;
  final String? failureReason;

  LoginAttempt({
    required this.id,
    required this.timestamp,
    required this.deviceInfo,
    required this.location,
    required this.ipAddress,
    required this.userAgent,
    required this.isSuccessful,
    this.failureReason,
  });
}
