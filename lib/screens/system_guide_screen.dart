import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SystemGuideScreen extends StatefulWidget {
  const SystemGuideScreen({super.key});

  @override
  State<SystemGuideScreen> createState() => _SystemGuideScreenState();
}

class _SystemGuideScreenState extends State<SystemGuideScreen> {
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
          'System Guide',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildHowToUseSection(),
            const SizedBox(height: 24),
            _buildRankingRulesSection(),
            const SizedBox(height: 24),
            _buildStudyRulesSection(),
            const SizedBox(height: 24),
            _buildTipsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple,
            AppTheme.darkPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to S-Rank',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your comprehensive learning and ranking system',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseSection() {
    return _buildSectionCard(
      title: 'How to Use the System',
      icon: Icons.play_circle_outline,
      children: [
        _buildStepItem(
          step: '1',
          title: 'Create Your Profile',
          description: 'Set up your account with profile information including gender, nickname, and birthday.',
        ),
        _buildStepItem(
          step: '2',
          title: 'Browse Courses & Decks',
          description: 'Explore available courses and create flashcard decks. Use search functionality to find specific content.',
        ),
        _buildStepItem(
          step: '3',
          title: 'Start Studying',
          description: 'Begin study sessions with flashcards. Choose study modes (Review, Due Cards, Random, or Difficult) and rate your performance.',
        ),
        _buildStepItem(
          step: '4',
          title: 'Track Progress',
          description: 'Monitor your learning progress, accuracy, streaks, and ranking improvements in your dashboard and leaderboard.',
        ),
        _buildStepItem(
          step: '5',
          title: 'Compete & Learn',
          description: 'View global leaderboards, track your rank position, and compete with other learners worldwide.',
        ),
      ],
    );
  }

  Widget _buildRankingRulesSection() {
    return _buildSectionCard(
      title: 'Ranking System Rules',
      icon: Icons.emoji_events,
      children: [
        _buildRuleItem(
          icon: Icons.trending_up,
          title: 'Point System',
          description: 'Earn points by correctly answering flashcards. Points are based on difficulty: Easy=1, Medium=2, Hard=3, Very Hard=4, Expert=5 points. Incorrect answers earn 0 points.',
        ),
        _buildRuleItem(
          icon: Icons.star,
          title: 'Rank Tiers',
          description: 'Progress through ranks: C-Rank (0-199 pts) → B-Rank (200-499 pts) → A-Rank (500-999 pts) → S-Rank (1000+ pts).',
        ),
        _buildRuleItem(
          icon: Icons.local_fire_department,
          title: 'Streak Tracking',
          description: 'Track your study streaks and maximum streaks achieved during study sessions for motivation and progress tracking.',
        ),
        _buildRuleItem(
          icon: Icons.psychology,
          title: 'Difficulty Levels',
          description: 'Flashcards have difficulty levels 1-5 (Easy to Expert). Higher difficulty cards earn more points when answered correctly.',
        ),
        _buildRuleItem(
          icon: Icons.timer,
          title: 'Time Tracking',
          description: 'Study sessions track time spent per card for analytics and progress monitoring, helping you understand your learning pace.',
        ),
        _buildRuleItem(
          icon: Icons.group,
          title: 'Global Leaderboard',
          description: 'Compete on global leaderboards with top 100 users. Your rank position is calculated based on total points across all courses.',
        ),
      ],
    );
  }

  Widget _buildStudyRulesSection() {
    return _buildSectionCard(
      title: 'Study System Rules',
      icon: Icons.book,
      children: [
        _buildRuleItem(
          icon: Icons.repeat,
          title: 'Spaced Repetition',
          description: 'Cards use ease factors and intervals for optimal review timing. Cards you rate as "Again" appear sooner, while "Easy" cards have longer intervals.',
        ),
        _buildRuleItem(
          icon: Icons.quiz,
          title: 'Flashcard Types',
          description: 'Study different card types: Basic (front/back), Multiple Choice, Enumeration (lists), and Identification (with images).',
        ),
        _buildRuleItem(
          icon: Icons.schedule,
          title: 'Study Modes',
          description: 'Choose from Review All, Due Cards, Random order, or Difficult Cards only. Each mode adapts to your learning needs.',
        ),
        _buildRuleItem(
          icon: Icons.analytics,
          title: 'Session Tracking',
          description: 'Track study sessions with accuracy, completion rates, streaks, and time spent per card for detailed progress analysis.',
        ),
        _buildRuleItem(
          icon: Icons.flag,
          title: 'Card Rating System',
          description: 'Rate cards as Again (0-1 days), Hard (1-6 days), Good (1-10 days), or Easy (4+ days) to optimize review intervals.',
        ),
        _buildRuleItem(
          icon: Icons.celebration,
          title: 'Progress Metrics',
          description: 'Monitor your accuracy percentage, average time per card, total cards studied, and course completion rates.',
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return _buildSectionCard(
      title: 'Pro Tips for Success',
      icon: Icons.lightbulb,
      children: [
        _buildTipItem(
          tip: 'Rate Cards Honestly',
          description: 'Be honest when rating cards (Again, Hard, Good, Easy). This helps the spaced repetition algorithm work effectively.',
        ),
        _buildTipItem(
          tip: 'Use Study Modes Wisely',
          description: 'Start with "Review All" to learn new content, then use "Due Cards" for efficient review sessions.',
        ),
        _buildTipItem(
          tip: 'Focus on Accuracy',
          description: 'Prioritize correct answers over speed. Only correct answers earn points, and higher difficulty cards give more points.',
        ),
        _buildTipItem(
          tip: 'Track Your Progress',
          description: 'Monitor your accuracy percentage and study streaks. Consistent improvement is more valuable than perfect scores.',
        ),
        _buildTipItem(
          tip: 'Use Different Card Types',
          description: 'Mix Basic, Multiple Choice, Enumeration, and Identification cards to reinforce learning from different angles.',
        ),
        _buildTipItem(
          tip: 'Study Due Cards Daily',
          description: 'Check your due cards regularly. The spaced repetition system works best with consistent daily practice.',
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({
    required String tip,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tip,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}