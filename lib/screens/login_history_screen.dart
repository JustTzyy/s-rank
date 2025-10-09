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
  List<LoginSession> _loginSessions = [];

  @override
  void initState() {
    super.initState();
    _loadLoginHistory();
  }

  Future<void> _loadLoginHistory() async {
    try {
      setState(() => _isLoading = true);
      
      final user = _authService.currentUser;
      if (user != null) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('loginHistory')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

        _loginSessions = query.docs.map((doc) {
          final data = doc.data();
          return LoginSession.fromMap(data);
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
          : _loginSessions.isEmpty
              ? _buildEmptyState()
              : _buildLoginHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Login History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your login sessions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loginSessions.length,
      itemBuilder: (context, index) {
        final session = _loginSessions[index];
        return _buildLoginSessionCard(session);
      },
    );
  }

  Widget _buildLoginSessionCard(LoginSession session) {
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
            color: session.isSuccessful 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            session.isSuccessful ? Icons.check_circle : Icons.error,
            color: session.isSuccessful ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          session.isSuccessful ? 'Successful Login' : 'Failed Login',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDateTime(session.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (session.deviceInfo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                session.deviceInfo,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (session.ipAddress.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'IP: ${session.ipAddress}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (session.location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                session.location,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        trailing: session.isSuccessful
            ? Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondary,
              )
            : null,
        onTap: session.isSuccessful ? () => _showSessionDetails(session) : null,
      ),
    );
  }

  void _showSessionDetails(LoginSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Session Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', session.isSuccessful ? 'Successful' : 'Failed'),
            _buildDetailRow('Date & Time', _formatDateTime(session.timestamp)),
            if (session.deviceInfo.isNotEmpty)
              _buildDetailRow('Device', session.deviceInfo),
            if (session.ipAddress.isNotEmpty)
              _buildDetailRow('IP Address', session.ipAddress),
            if (session.location.isNotEmpty)
              _buildDetailRow('Location', session.location),
            if (session.userAgent.isNotEmpty)
              _buildDetailRow('User Agent', session.userAgent),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class LoginSession {
  final DateTime timestamp;
  final bool isSuccessful;
  final String deviceInfo;
  final String ipAddress;
  final String location;
  final String userAgent;
  final String? errorMessage;

  LoginSession({
    required this.timestamp,
    required this.isSuccessful,
    this.deviceInfo = '',
    this.ipAddress = '',
    this.location = '',
    this.userAgent = '',
    this.errorMessage,
  });

  factory LoginSession.fromMap(Map<String, dynamic> data) {
    return LoginSession(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isSuccessful: data['isSuccessful'] ?? false,
      deviceInfo: data['deviceInfo'] ?? '',
      ipAddress: data['ipAddress'] ?? '',
      location: data['location'] ?? '',
      userAgent: data['userAgent'] ?? '',
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'isSuccessful': isSuccessful,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'location': location,
      'userAgent': userAgent,
      'errorMessage': errorMessage,
    };
  }
}