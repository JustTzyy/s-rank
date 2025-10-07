import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'security_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecurityService _securityService = SecurityService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Save user profile data
  Future<void> saveUserProfile({
    required String userId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String gender,
    required DateTime birthday,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'gender': gender,
        'birthday': birthday,
        'points': 0,
        'rank': 'C',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user points
  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': points,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user points: $e');
    }
  }

  // Update user rank
  Future<void> updateUserRank(String userId, String rank) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'rank': rank,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user rank: $e');
    }
  }

  // Update both points and rank
  Future<void> updateUserPointsAndRank(String userId, int points, String rank) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': points,
        'rank': rank,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user points and rank: $e');
    }
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(email);
        await user.reload();
      }
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile({
    String? displayName,
    String? gender,
    DateTime? birthday,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (displayName != null) {
          updateData['displayName'] = displayName;
        }
        if (gender != null) {
          updateData['gender'] = gender;
        }
        if (birthday != null) {
          updateData['birthday'] = birthday;
        }
        if (additionalData != null) {
          updateData.addAll(additionalData);
        }
        
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }
      
      await user.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }



  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
