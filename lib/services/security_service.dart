import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityService {
  static SecurityService? _instance;
  
  factory SecurityService() {
    _instance ??= SecurityService._internal();
    return _instance!;
  }
  
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user has 2FA enabled
  Future<bool> isTwoFactorEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['twoFactorEnabled'] ?? false;
    } catch (e) {
      print('Error checking 2FA status: $e');
      return false;
    }
  }

  // Check if user has login notifications enabled
  Future<bool> hasLoginNotificationsEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['loginNotifications'] ?? true;
    } catch (e) {
      print('Error checking login notifications: $e');
      return true;
    }
  }

  // Check if user has suspicious activity alerts enabled
  Future<bool> hasSuspiciousActivityAlertsEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['suspiciousActivityAlerts'] ?? true;
    } catch (e) {
      print('Error checking suspicious activity alerts: $e');
      return true;
    }
  }

  // Get security score
  Future<int> getSecurityScore() async {
    try {
      int score = 0;
      
      // Check 2FA
      if (await isTwoFactorEnabled()) score += 40;
      
      // Check login notifications
      if (await hasLoginNotificationsEnabled()) score += 20;
      
      // Check suspicious activity alerts
      if (await hasSuspiciousActivityAlertsEnabled()) score += 20;
      
      // Check if user has a strong password (this would need to be implemented)
      // For now, we'll assume all users have strong passwords
      score += 20;
      
      return score;
    } catch (e) {
      print('Error calculating security score: $e');
      return 0;
    }
  }

  // Check if login attempt is suspicious
  Future<bool> isSuspiciousLogin({
    required String deviceInfo,
    required String userAgent,
    String? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get recent login attempts
      final recentLogins = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('loginHistory')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (recentLogins.docs.isEmpty) return false;

      // Check for unusual patterns
      final currentDevice = deviceInfo;
      final currentUserAgent = userAgent;

      // Check if device is new
      bool isNewDevice = true;
      for (final doc in recentLogins.docs) {
        final data = doc.data();
        if (data['deviceInfo'] == currentDevice) {
          isNewDevice = false;
          break;
        }
      }

      // Check if user agent is significantly different
      bool isUnusualUserAgent = false;
      if (recentLogins.docs.isNotEmpty) {
        final lastLogin = recentLogins.docs.first.data();
        final lastUserAgent = lastLogin['userAgent'] ?? '';
        
        // Simple check for major differences in user agent
        if (lastUserAgent.isNotEmpty && 
            !currentUserAgent.contains(lastUserAgent.split(' ')[0])) {
          isUnusualUserAgent = true;
        }
      }

      // Consider it suspicious if it's a new device or unusual user agent
      return isNewDevice || isUnusualUserAgent;
    } catch (e) {
      print('Error checking suspicious login: $e');
      return false;
    }
  }

  // Send security alert
  Future<void> sendSecurityAlert({
    required String type,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user has security alerts enabled
      if (!await hasSuspiciousActivityAlertsEnabled()) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('securityAlerts')
          .add({
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'additionalData': additionalData ?? {},
      });
    } catch (e) {
      print('Error sending security alert: $e');
    }
  }

  // Get recent security alerts
  Future<List<SecurityAlert>> getRecentSecurityAlerts({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final alerts = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('securityAlerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return alerts.docs.map((doc) => SecurityAlert.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting security alerts: $e');
      return [];
    }
  }

  // Mark security alert as read
  Future<void> markSecurityAlertAsRead(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('securityAlerts')
          .doc(alertId)
          .update({'read': true});
    } catch (e) {
      print('Error marking security alert as read: $e');
    }
  }

  // Verify 2FA code (placeholder implementation)
  Future<bool> verifyTwoFactorCode(String code) async {
    try {
      // In a real implementation, this would verify the code with the authenticator app
      // For now, we'll simulate verification
      await Future.delayed(const Duration(seconds: 1));
      
      // Simple validation - in real app, this would be much more sophisticated
      return code.length == 6 && code.contains(RegExp(r'^\d+$'));
    } catch (e) {
      print('Error verifying 2FA code: $e');
      return false;
    }
  }

  // Generate backup codes
  List<String> generateBackupCodes({int count = 10}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(count, (index) {
      return List.generate(8, (i) => 
        chars[(DateTime.now().millisecondsSinceEpoch + index + i) % chars.length]
      ).join();
    });
  }

  // Save backup codes
  Future<void> saveBackupCodes(List<String> codes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('security')
          .doc('backupCodes')
          .set({
        'codes': codes,
        'createdAt': FieldValue.serverTimestamp(),
        'used': List.filled(codes.length, false),
      });
    } catch (e) {
      print('Error saving backup codes: $e');
    }
  }

  // Get backup codes
  Future<List<String>?> getBackupCodes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('security')
          .doc('backupCodes')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return List<String>.from(data['codes'] ?? []);
      }
      return null;
    } catch (e) {
      print('Error getting backup codes: $e');
      return null;
    }
  }
}

class SecurityAlert {
  final String id;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool read;
  final Map<String, dynamic> additionalData;

  SecurityAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
    required this.additionalData,
  });

  factory SecurityAlert.fromMap(Map<String, dynamic> data) {
    return SecurityAlert(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      additionalData: data['additionalData'] ?? {},
    );
  }
}
