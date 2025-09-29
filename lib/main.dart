import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Srank',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        
        // User is logged in, check if they have completed profile setup
        return FutureBuilder(
          future: authService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final profile = profileSnapshot.data;
            if (profile == null) {
              // User needs to complete profile setup
              return const ProfileSetupScreen();
            } else {
              // User has completed profile setup
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
