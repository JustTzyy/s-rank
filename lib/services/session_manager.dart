import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class SessionManager extends ChangeNotifier {
  final AuthService _authService = AuthService();
  Timer? _activityTimer;
  String? _currentSessionId;
  bool _isActive = false;

  // Initialize session manager
  void initialize() {
    _startActivityTracking();
  }

  // Start tracking user activity
  void _startActivityTracking() {
    if (_isActive) return;
    
    _isActive = true;
    _currentSessionId = _authService.generateSessionId();
    
    // Update activity every 5 minutes
    _activityTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateActivity();
    });
    
    // Initial activity update
    _updateActivity();
  }

  // Update session activity
  Future<void> _updateActivity() async {
    if (_currentSessionId != null) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          // Check if session exists before updating
          final sessionDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('activeSessions')
              .doc(_currentSessionId!)
              .get();
          
          if (sessionDoc.exists) {
            await _authService.updateSessionActivity(_currentSessionId!);
          } else {
            // Session doesn't exist, create a new one
            await _authService.createOrUpdateActiveSession(
              sessionId: _currentSessionId!,
              deviceInfo: _authService.getDeviceInfo(),
              userAgent: _authService.getUserAgent(),
            );
          }
        }
      } catch (e) {
        debugPrint('Error updating session activity: $e');
        // If there's an error, stop the timer to prevent spam
        stop();
      }
    }
  }

  // Stop activity tracking
  void stop() {
    _isActive = false;
    _activityTimer?.cancel();
    _activityTimer = null;
    _currentSessionId = null;
  }

  // Resume activity tracking
  void resume() {
    if (!_isActive) {
      _startActivityTracking();
    }
  }

  // Get current session ID
  String? get currentSessionId => _currentSessionId;

  // Check if session manager is active
  bool get isActive => _isActive;

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
