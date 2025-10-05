import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConditionsSettingsScreen extends StatefulWidget {
  const ConditionsSettingsScreen({super.key});

  @override
  State<ConditionsSettingsScreen> createState() => _ConditionsSettingsScreenState();
}

class _ConditionsSettingsScreenState extends State<ConditionsSettingsScreen> {
  String _studyEnvironment = 'Home';
  String _noiseLevel = 'Normal';
  String _studyDuration = '30min';
  String _difficulty = 'Medium';

  @override
  Widget build(BuildContext context) {
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
          'Study Conditions',
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
            title: 'Environment Settings',
            children: [
              _buildStudyEnvironmentSetting(),
              const SizedBox(height: 16),
              _buildNoiseLevelSetting(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Study Preferences',
            children: [
              _buildStudyDurationSetting(),
              const SizedBox(height: 16),
              _buildDifficultySetting(),
            ],
          ),
        ],
      ),
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

  Widget _buildStudyEnvironmentSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Environment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildEnvironmentOption('Home', Icons.home),
            _buildEnvironmentOption('Library', Icons.local_library),
            _buildEnvironmentOption('Office', Icons.business),
            _buildEnvironmentOption('Other', Icons.location_on),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentOption(String environment, IconData icon) {
    final isSelected = _studyEnvironment == environment;
    return GestureDetector(
      onTap: () {
        setState(() {
          _studyEnvironment = environment;
        });
        _showSnackBar('Study environment set to $environment');
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              environment,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoiseLevelSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Noise Level',
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
              child: _buildNoiseOption('Quiet', Icons.volume_off, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNoiseOption('Normal', Icons.volume_down, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNoiseOption('Noisy', Icons.volume_up, Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoiseOption(String level, IconData icon, Color color) {
    final isSelected = _noiseLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() {
          _noiseLevel = level;
        });
        _showSnackBar('Noise level set to $level');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 4),
            Text(
              level,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyDurationSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study Duration',
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
              child: _buildDurationOption('15min'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDurationOption('30min'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDurationOption('45min'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDurationOption('60min'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationOption(String duration) {
    final isSelected = _studyDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() {
          _studyDuration = duration;
        });
        _showSnackBar('Study duration set to $duration');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          duration,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty Level',
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
              child: _buildDifficultyOption('Easy', Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyOption('Medium', Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDifficultyOption('Hard', Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(String difficulty, Color color) {
    final isSelected = _difficulty == difficulty;
    return GestureDetector(
      onTap: () {
        setState(() {
          _difficulty = difficulty;
        });
        _showSnackBar('Difficulty set to $difficulty');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          difficulty,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
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
