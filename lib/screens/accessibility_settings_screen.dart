import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/accessibility_service.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  final AccessibilityService _accessibilityService = AccessibilityService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _accessibilityService,
      builder: (context, child) {
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
          'Accessibility',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: 'Display Settings',
            children: [
              _buildFontSizeSetting(),
              const SizedBox(height: 16),
              _buildDarkModeSetting(),
              const SizedBox(height: 16),
              _buildHighContrastSetting(),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Font Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFontSizeOption('Small', 'S'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFontSizeOption('Medium', 'M'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFontSizeOption('Large', 'L'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontSizeOption(String label, String size) {
    final isSelected = _accessibilityService.fontSize == label;
    return GestureDetector(
      onTap: () async {
        await _accessibilityService.updateFontSize(label);
        _showSnackBar('Font size set to $label');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              size,
              style: TextStyle(
                fontSize: isSelected ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeSetting() {
    return SwitchListTile(
      title: const Text(
        'Dark Mode',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: const Text(
        'Switch to dark theme for better visibility in low light',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      value: _accessibilityService.darkMode,
      onChanged: (value) async {
        await _accessibilityService.updateDarkMode(value);
        _showSnackBar(value ? 'Dark mode enabled' : 'Dark mode disabled');
      },
      activeColor: AppTheme.primaryPurple,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildHighContrastSetting() {
    return SwitchListTile(
      title: const Text(
        'High Contrast',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: const Text(
        'Increase contrast for better readability',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
      value: _accessibilityService.highContrast,
      onChanged: (value) async {
        await _accessibilityService.updateHighContrast(value);
        _showSnackBar(value ? 'High contrast enabled' : 'High contrast disabled');
      },
      activeColor: AppTheme.primaryPurple,
      contentPadding: EdgeInsets.zero,
    );
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
