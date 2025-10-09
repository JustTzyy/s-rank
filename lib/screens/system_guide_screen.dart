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
          description: 'Set up your account with profile information including gender, first name, middle name, last name, and birthday.',
        ),
        _buildStepItem(
          step: '2',
          title: 'Browse Courses & Decks',
          description: 'Explore available courses and create flashcard decks. Use search functionality to find specific content.',
        ),
        _buildStepItem(
          step: '3',
          title: 'Study with Flashcards',
          description: 'Choose from 4 study modes: Review All, Due Cards, Random order, or Difficult Cards only. Study different card types including Basic, Multiple Choice, Enumeration, and Identification.',
        ),
        _buildStepItem(
          step: '4',
          title: 'Take Challenges',
          description: 'Complete challenges to earn points and improve your rank. Challenges test your knowledge with various flashcard types and track your accuracy.',
        ),
        _buildStepItem(
          step: '5',
          title: 'Track Progress & Compete',
          description: 'Monitor your learning progress, accuracy, and study streaks. View global leaderboards and track your rank position to compete with other learners.',
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
          description: 'Earn points by correctly answering flashcards in challenges. Points are calculated based on difficulty level (1-5) and time spent. Study sessions track progress but only challenges award ranking points.',
        ),
        _buildRuleItem(
          icon: Icons.star,
          title: 'Rank Tiers',
          description: 'Progress through ranks: C-Rank → B-Rank → A-Rank → S-Rank. Your rank is determined by your total points earned from completing challenges.',
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
          icon: Icons.quiz,
          title: 'Flashcard Types',
          description: 'Study 4 different card types: Basic (front/back), Multiple Choice (with options), Enumeration (lists), and Identification (with images). Each type tests different learning skills.',
        ),
        _buildRuleItem(
          icon: Icons.schedule,
          title: 'Study Modes',
          description: 'Choose from 4 study modes: Review All (all cards), Due Cards (cards needing review), Random (shuffled order), or Difficult (hard cards only).',
        ),
        _buildRuleItem(
          icon: Icons.analytics,
          title: 'Progress Tracking',
          description: 'Track your study progress with accuracy percentages, cards studied, study time, and streaks. Set custom daily and weekly goals.',
        ),
        _buildRuleItem(
          icon: Icons.flag,
          title: 'Difficulty Levels',
          description: 'Flashcards have difficulty levels 1-5 (Easy to Expert). Higher difficulty cards provide more challenge and better learning outcomes.',
        ),
        _buildRuleItem(
          icon: Icons.celebration,
          title: 'Challenge System',
          description: 'Complete challenges to earn ranking points. Challenges test your knowledge across all flashcard types and track your performance.',
        ),
        _buildRuleItem(
          icon: Icons.timer,
          title: 'Time Tracking',
          description: 'Study sessions track time spent per card and total session duration for detailed progress analysis and goal tracking.',
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
          tip: 'Use Study Modes Wisely',
          description: 'Start with "Review All" to learn new content, then use "Due Cards" for efficient review sessions. Use "Random" for variety and "Difficult" to focus on challenging cards.',
        ),
        _buildTipItem(
          tip: 'Focus on Accuracy',
          description: 'Prioritize correct answers over speed. Only correct answers in challenges earn ranking points, and higher difficulty cards provide better learning outcomes.',
        ),
        _buildTipItem(
          tip: 'Track Your Progress',
          description: 'Monitor your accuracy percentage, study streaks, and goal progress. Set realistic daily and weekly goals to maintain motivation.',
        ),
        _buildTipItem(
          tip: 'Use Different Card Types',
          description: 'Mix Basic, Multiple Choice, Enumeration, and Identification cards to reinforce learning from different angles and improve retention.',
        ),
        _buildTipItem(
          tip: 'Take Regular Challenges',
          description: 'Complete challenges regularly to earn ranking points and test your knowledge. Challenges are the primary way to improve your rank.',
        ),
        _buildTipItem(
          tip: 'Study Consistently',
          description: 'Maintain regular study sessions to build streaks and achieve your goals. Consistent practice is more valuable than occasional intensive sessions.',
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