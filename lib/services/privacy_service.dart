import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacyService {
  static PrivacyService? _instance;
  
  factory PrivacyService() {
    _instance ??= PrivacyService._internal();
    return _instance!;
  }
  
  PrivacyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Privacy Settings
  Future<PrivacySettings?> getPrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('privacy')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return PrivacySettings.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error loading privacy settings: $e');
      return null;
    }
  }

  Future<void> savePrivacySettings(PrivacySettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('privacy')
          .set(settings.toMap());
    } catch (e) {
      print('Error saving privacy settings: $e');
      throw Exception('Failed to save privacy settings: $e');
    }
  }

  // Check if data collection is allowed
  Future<bool> canCollectStudyData() async {
    final settings = await getPrivacySettings();
    return settings?.collectStudyData ?? true;
  }

  Future<bool> canCollectDeviceInfo() async {
    final settings = await getPrivacySettings();
    return settings?.collectDeviceInfo ?? true;
  }

  Future<bool> canCollectLocationData() async {
    final settings = await getPrivacySettings();
    return settings?.collectLocationData ?? false;
  }

  Future<bool> canCollectUsagePatterns() async {
    final settings = await getPrivacySettings();
    return settings?.collectUsagePatterns ?? true;
  }

  // Check if data sharing is allowed
  Future<bool> canShareAnalytics() async {
    final settings = await getPrivacySettings();
    return settings?.shareAnalytics ?? true;
  }

  Future<bool> canShareUsageData() async {
    final settings = await getPrivacySettings();
    return settings?.shareUsageData ?? false;
  }

  Future<bool> canShareCrashReports() async {
    final settings = await getPrivacySettings();
    return settings?.shareCrashReports ?? true;
  }

  Future<bool> canSharePerformanceData() async {
    final settings = await getPrivacySettings();
    return settings?.sharePerformanceData ?? true;
  }

  // Check social privacy settings
  Future<bool> canShowOnlineStatus() async {
    final settings = await getPrivacySettings();
    return settings?.showOnlineStatus ?? true;
  }

  Future<bool> canAllowFriendRequests() async {
    final settings = await getPrivacySettings();
    return settings?.allowFriendRequests ?? true;
  }

  Future<bool> canAllowLeaderboard() async {
    final settings = await getPrivacySettings();
    return settings?.allowLeaderboard ?? true;
  }

  Future<bool> canAllowChallenges() async {
    final settings = await getPrivacySettings();
    return settings?.allowChallenges ?? true;
  }

  // Check profile privacy settings
  Future<bool> isProfilePublic() async {
    final settings = await getPrivacySettings();
    return settings?.profilePublic ?? false;
  }

  Future<bool> canShowStudyProgress() async {
    final settings = await getPrivacySettings();
    return settings?.showStudyProgress ?? true;
  }

  Future<bool> canShowAchievements() async {
    final settings = await getPrivacySettings();
    return settings?.showAchievements ?? true;
  }

  Future<bool> canShowStreaks() async {
    final settings = await getPrivacySettings();
    return settings?.showStreaks ?? true;
  }

  Future<bool> canShowPoints() async {
    final settings = await getPrivacySettings();
    return settings?.showPoints ?? true;
  }

  // Data retention and export
  Future<int> getDataRetentionPeriod() async {
    final settings = await getPrivacySettings();
    return settings?.dataRetentionPeriod ?? 365;
  }

  Future<bool> canAutoDeleteOldData() async {
    final settings = await getPrivacySettings();
    return settings?.autoDeleteOldData ?? true;
  }

  Future<bool> canExportData() async {
    final settings = await getPrivacySettings();
    return settings?.allowDataExport ?? true;
  }

  Future<bool> canDeleteData() async {
    final settings = await getPrivacySettings();
    return settings?.allowDataDeletion ?? true;
  }
}

class PrivacySettings {
  // Profile Privacy Settings
  final bool profilePublic;
  final bool showStudyProgress;
  final bool showAchievements;
  final bool showStreaks;
  final bool showPoints;

  // Data Sharing Settings
  final bool shareAnalytics;
  final bool shareUsageData;
  final bool shareCrashReports;
  final bool sharePerformanceData;

  // Social Privacy Settings
  final bool allowFriendRequests;
  final bool showOnlineStatus;
  final bool allowLeaderboard;
  final bool allowChallenges;

  // Data Collection Settings
  final bool collectStudyData;
  final bool collectDeviceInfo;
  final bool collectLocationData;
  final bool collectUsagePatterns;

  // Data Retention Settings
  final int dataRetentionPeriod;
  final bool autoDeleteOldData;
  final bool allowDataExport;
  final bool allowDataDeletion;

  PrivacySettings({
    this.profilePublic = false,
    this.showStudyProgress = true,
    this.showAchievements = true,
    this.showStreaks = true,
    this.showPoints = true,
    this.shareAnalytics = true,
    this.shareUsageData = false,
    this.shareCrashReports = true,
    this.sharePerformanceData = true,
    this.allowFriendRequests = true,
    this.showOnlineStatus = true,
    this.allowLeaderboard = true,
    this.allowChallenges = true,
    this.collectStudyData = true,
    this.collectDeviceInfo = true,
    this.collectLocationData = false,
    this.collectUsagePatterns = true,
    this.dataRetentionPeriod = 365,
    this.autoDeleteOldData = true,
    this.allowDataExport = true,
    this.allowDataDeletion = true,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> data) {
    return PrivacySettings(
      profilePublic: data['profilePublic'] ?? false,
      showStudyProgress: data['showStudyProgress'] ?? true,
      showAchievements: data['showAchievements'] ?? true,
      showStreaks: data['showStreaks'] ?? true,
      showPoints: data['showPoints'] ?? true,
      shareAnalytics: data['shareAnalytics'] ?? true,
      shareUsageData: data['shareUsageData'] ?? false,
      shareCrashReports: data['shareCrashReports'] ?? true,
      sharePerformanceData: data['sharePerformanceData'] ?? true,
      allowFriendRequests: data['allowFriendRequests'] ?? true,
      showOnlineStatus: data['showOnlineStatus'] ?? true,
      allowLeaderboard: data['allowLeaderboard'] ?? true,
      allowChallenges: data['allowChallenges'] ?? true,
      collectStudyData: data['collectStudyData'] ?? true,
      collectDeviceInfo: data['collectDeviceInfo'] ?? true,
      collectLocationData: data['collectLocationData'] ?? false,
      collectUsagePatterns: data['collectUsagePatterns'] ?? true,
      dataRetentionPeriod: data['dataRetentionPeriod'] ?? 365,
      autoDeleteOldData: data['autoDeleteOldData'] ?? true,
      allowDataExport: data['allowDataExport'] ?? true,
      allowDataDeletion: data['allowDataDeletion'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profilePublic': profilePublic,
      'showStudyProgress': showStudyProgress,
      'showAchievements': showAchievements,
      'showStreaks': showStreaks,
      'showPoints': showPoints,
      'shareAnalytics': shareAnalytics,
      'shareUsageData': shareUsageData,
      'shareCrashReports': shareCrashReports,
      'sharePerformanceData': sharePerformanceData,
      'allowFriendRequests': allowFriendRequests,
      'showOnlineStatus': showOnlineStatus,
      'allowLeaderboard': allowLeaderboard,
      'allowChallenges': allowChallenges,
      'collectStudyData': collectStudyData,
      'collectDeviceInfo': collectDeviceInfo,
      'collectLocationData': collectLocationData,
      'collectUsagePatterns': collectUsagePatterns,
      'dataRetentionPeriod': dataRetentionPeriod,
      'autoDeleteOldData': autoDeleteOldData,
      'allowDataExport': allowDataExport,
      'allowDataDeletion': allowDataDeletion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
