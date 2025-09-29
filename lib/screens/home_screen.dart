import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('No user logged in'));
          }
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Srank!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email: ${user.email}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'UID: ${user.uid}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder(
                          future: authService.getUserProfile(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            
                            final profile = snapshot.data;
                            if (profile == null) {
                              return const Text('No profile data found');
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('First Name: ${profile['firstName'] ?? 'Not set'}'),
                                const SizedBox(height: 8),
                                Text('Middle Name: ${profile['middleName'] ?? 'Not set'}'),
                                const SizedBox(height: 8),
                                Text('Last Name: ${profile['lastName'] ?? 'Not set'}'),
                                const SizedBox(height: 8),
                                Text('Gender: ${profile['gender'] ?? 'Not set'}'),
                                const SizedBox(height: 8),
                                Text('Birthday: ${profile['birthday'] != null ? 
                                  DateTime.fromMillisecondsSinceEpoch(profile['birthday'].millisecondsSinceEpoch).toString().split(' ')[0] 
                                  : 'Not set'}'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
