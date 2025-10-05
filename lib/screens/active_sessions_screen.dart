import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<ActiveSession> _activeSessions = [];
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load active sessions from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('activeSessions')
            .where('isActive', isEqualTo: true)
            .orderBy('lastActivity', descending: true)
            .get();
        
        _activeSessions = snapshot.docs.map((doc) {
          final data = doc.data();
          final session = ActiveSession(
            id: doc.id,
            deviceInfo: data['deviceInfo'] ?? 'Unknown Device',
            location: data['location'] ?? 'Unknown Location',
            ipAddress: data['ipAddress'] ?? 'Unknown IP',
            userAgent: data['userAgent'] ?? 'Unknown Browser',
            lastActivity: (data['lastActivity'] as Timestamp).toDate(),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            isCurrentSession: data['isCurrentSession'] ?? false,
          );
          
          if (session.isCurrentSession) {
            _currentSessionId = session.id;
          }
          
          return session;
        }).toList();
      }
    } catch (e) {
      print('Error loading active sessions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeSession(ActiveSession session) async {
    if (session.isCurrentSession) {
      _showErrorDialog('Cannot revoke current session', 
          'You cannot revoke your current session. Please use a different device to revoke this session.');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Revoke Session',
      content: 'Are you sure you want to revoke access for "${session.deviceInfo}"? This will log out the device immediately.',
      confirmText: 'Revoke Access',
    );

    if (!confirmed) return;

    try {
      // Mark session as inactive in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_authService.currentUser!.uid)
          .collection('activeSessions')
          .doc(session.id)
          .update({
        'isActive': false,
        'revokedAt': FieldValue.serverTimestamp(),
      });

      // Reload sessions
      await _loadActiveSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session revoked for ${session.deviceInfo}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revoke session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _revokeAllOtherSessions() async {
    final otherSessions = _activeSessions.where((s) => !s.isCurrentSession).toList();
    
    if (otherSessions.isEmpty) {
      _showErrorDialog('No Other Sessions', 'There are no other active sessions to revoke.');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      title: 'Revoke All Other Sessions',
      content: 'Are you sure you want to revoke access for all other devices? This will log out ${otherSessions.length} device(s) immediately.',
      confirmText: 'Revoke All',
    );

    if (!confirmed) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final session in otherSessions) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('activeSessions')
            .doc(session.id);
        
        batch.update(docRef, {
          'isActive': false,
          'revokedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _loadActiveSessions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Revoked ${otherSessions.length} session(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revoke sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Active Sessions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_activeSessions.where((s) => !s.isCurrentSession).isNotEmpty)
            TextButton(
              onPressed: _revokeAllOtherSessions,
              child: const Text(
                'Revoke All',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeSessions.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    
                    // Active Sessions List
                    Expanded(
                      child: _buildSessionsList(),
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
            Icons.devices,
            size: 64,
            color: AppTheme.primaryPurple.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your active sessions will appear here',
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
    final currentSessions = _activeSessions.where((s) => s.isCurrentSession).length;
    final otherSessions = _activeSessions.where((s) => !s.isCurrentSession).length;
    final uniqueDevices = _activeSessions.map((s) => s.deviceInfo).toSet().length;
    
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
                'Total Sessions',
                '${_activeSessions.length}',
                Icons.devices,
                AppTheme.primaryPurple,
              ),
              _buildSummaryItem(
                'Current Device',
                '$currentSessions',
                Icons.phone_android,
                Colors.green,
              ),
              _buildSummaryItem(
                'Other Devices',
                '$otherSessions',
                Icons.devices_other,
                Colors.orange,
              ),
              _buildSummaryItem(
                'Unique Devices',
                '$uniqueDevices',
                Icons.device_hub,
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

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _activeSessions.length,
      itemBuilder: (context, index) {
        final session = _activeSessions[index];
        return _buildSessionItem(session);
      },
    );
  }

  Widget _buildSessionItem(ActiveSession session) {
    final isRecent = DateTime.now().difference(session.lastActivity).inHours < 24;
    final statusColor = session.isCurrentSession ? Colors.green : Colors.blue;
    final statusIcon = session.isCurrentSession ? Icons.phone_android : Icons.devices;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: session.isCurrentSession 
            ? Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), width: 2)
            : null,
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.deviceInfo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (session.isCurrentSession)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.location,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Last active: ${_formatTimestamp(session.lastActivity)}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            if (isRecent) ...[
              const SizedBox(height: 2),
              Text(
                'Active recently',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: session.isCurrentSession
            ? const Icon(
                Icons.lock,
                color: Colors.grey,
                size: 20,
              )
            : IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _revokeSession(session),
              ),
        onTap: () => _showSessionDetails(session),
      ),
    );
  }

  void _showSessionDetails(ActiveSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              session.isCurrentSession ? Icons.phone_android : Icons.devices,
              color: session.isCurrentSession ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Session Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Device', session.deviceInfo),
            _buildDetailRow('Location', session.location),
            _buildDetailRow('IP Address', session.ipAddress),
            _buildDetailRow('Browser', session.userAgent),
            _buildDetailRow('Created', _formatDetailedTimestamp(session.createdAt)),
            _buildDetailRow('Last Active', _formatDetailedTimestamp(session.lastActivity)),
            _buildDetailRow('Status', session.isCurrentSession ? 'Current Session' : 'Active'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!session.isCurrentSession)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _revokeSession(session);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Revoke'),
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

  void _showErrorDialog(String title, String content) {
    showDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

class ActiveSession {
  final String id;
  final String deviceInfo;
  final String location;
  final String ipAddress;
  final String userAgent;
  final DateTime lastActivity;
  final DateTime createdAt;
  final bool isCurrentSession;

  ActiveSession({
    required this.id,
    required this.deviceInfo,
    required this.location,
    required this.ipAddress,
    required this.userAgent,
    required this.lastActivity,
    required this.createdAt,
    required this.isCurrentSession,
  });
}
