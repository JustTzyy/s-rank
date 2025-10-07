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
      
      // Check login notifications
      if (await hasLoginNotificationsEnabled()) score += 40;
      
      // Check suspicious activity alerts
      if (await hasSuspiciousActivityAlertsEnabled()) score += 40;
      
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
