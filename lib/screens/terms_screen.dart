import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By using Srank, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
            ),
            
            _buildSection(
              context,
              '2. Use License',
              'Permission is granted to temporarily use Srank for personal, non-commercial transitory viewing only.',
            ),
            
            _buildSection(
              context,
              '3. User Accounts',
              'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
            ),
            
            _buildSection(
              context,
              '4. Privacy',
              'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the app.',
            ),
            
            _buildSection(
              context,
              '5. Prohibited Uses',
              'You may not use our app for any unlawful purpose or to solicit others to perform unlawful acts.',
            ),
            
            _buildSection(
              context,
              '6. Content',
              'Our app allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material.',
            ),
            
            _buildSection(
              context,
              '7. Termination',
              'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever.',
            ),
            
            _buildSection(
              context,
              '8. Changes to Terms',
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time.',
            ),
            
            _buildSection(
              context,
              '9. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at support@srank.com.',
            ),
            
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I Understand'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
