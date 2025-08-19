            // Simplified QuizScreen - Preserving all functionality while removing complex animations
import 'package:flutter/material.dart';
import 'package:ultsukulu/managers/streak_manager.dart';
import 'package:ultsukulu/managers/token_manager.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentStreak = 0;
  bool _isStreakActive = false;
  int _currentTokens = 0;
  bool _dailyBonusAvailable = false;
  String _currentMotivationalMessage = '';

  // Duolingo-style motivational messages
  final List<String> _motivationalMessages = [
    "Ready to prove you're a genius? 🧠",
    "I bet you can't get all answers right! 😏",
    "Your brain needs a workout! 💪",
    "Challenge accepted? Let's see! 🎯",
    "Think you're smart enough? Prove it! 🔥",
    "Dare to test your knowledge? 🚀",
    "Can you handle the difficulty? 😤",
    "Your streak is waiting... Don't break it! ⚡",
    "Time to show off your skills! ✨",
    "Are you brave enough to start? 🦁",
    "Knowledge is power. Gain some! 💎",
    "Your future self will thank you! 🌟",
    "Don't let your brain get rusty! 🧩",
    "Champions never skip practice! 🏆",
    "Every expert was once a beginner! 🌱",
  ];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
    _loadTokenData();
    _updateMotivationalMessage();
    _startPeriodicMessageUpdate();
  }

  void _updateMotivationalMessage() {
    final random = Random();
    if (mounted) {
      setState(() {
        _currentMotivationalMessage =
            _motivationalMessages[random.nextInt(_motivationalMessages.length)];
      });
    }
  }

  void _startPeriodicMessageUpdate() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _updateMotivationalMessage();
        _startPeriodicMessageUpdate();
      }
    });
  }

  Future<void> _loadStreakData() async {
    final stats = await StreakManager.instance.getStreakStats();
    if (mounted) {
      setState(() {
        _currentStreak = stats['currentStreak'];
        _isStreakActive = stats['isActive'];
      });
    }
  }

  Future<void> _loadTokenData() async {
    final tokenStats = await TokenManager.instance.getTokenStats();
    if (mounted) {
      setState(() {
        _currentTokens = tokenStats.currentTokens;
        _dailyBonusAvailable = tokenStats.dailyBonusAvailable;
      });
    }
  }

  // Call this method when a quiz is completed
  Future<void> _onQuizCompleted(
    String subject,
    int score,
    int totalQuestions,
  ) async {
    final results = await StreakManager.instance.completeQuiz(subject);

    // Award tokens for quiz completion
    await TokenManager.instance.awardQuizCompletion(score, totalQuestions);

    // Award streak bonus if applicable
    if (results['currentStreak']! > _currentStreak) {
      await TokenManager.instance.awardStreakBonus(results['currentStreak']!);
    }

    if (mounted) {
      setState(() {
        _currentStreak = results['currentStreak']!;
        _isStreakActive = true;
      });

      // Reload token data to reflect earnings
      await _loadTokenData();

      // Show celebration if streak increased
      if (results['currentStreak']! > _currentStreak) {
        _showStreakCelebration();
      }
    }
  }

  Future<void> _claimDailyBonus() async {
    final result = await TokenManager.instance.claimDailyBonus();

    if (result.success) {
      await _loadTokenData();
      _showDailyBonusDialog(result);
    } else {
      _showErrorDialog('Daily Bonus', result.message);
    }
  }

  void _showDailyBonusDialog(DailyBonusResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade300, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🎉 DAILY BONUS! 🎉',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.grey[800],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
                child: const Text(
                  'AWESOME! 🚀',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTokenShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TokenShopBottomSheet(onTokensUpdated: _loadTokenData),
    );
  }

  void _showStreakCelebration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🔥 STREAK MASTER! 🔥',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.grey[800],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re unstoppable!\n$_currentStreak days and counting!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                  shadowColor: Colors.orange.withOpacity(0.4),
                ),
                child: const Text(
                  'KEEP GOING! 💪',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CC02), // Duolingo green background
      body: SafeArea(
        child: Column(
          children: [
            // Header with app title, tokens, and streak
            _buildHeader(),

            // Main content area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Daily bonus banner (if available)
                    if (_dailyBonusAvailable) _buildDailyBonusBanner(),

                    // Motivational message banner
                    _buildMotivationalBanner(),

                    // Subjects grid
                    Expanded(child: _buildSubjectsGrid()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // App logo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.school, color: Color(0xFF58CC02), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'ISUKULU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
          // Token display
          TokenDisplay(tokens: _currentTokens, onTap: _showTokenShop),
          const SizedBox(width: 12),
          // Streak display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: _isStreakActive ? Colors.orange.shade600 : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_currentStreak',
                  style: TextStyle(
                    color: _isStreakActive
                        ? Colors.orange.shade600
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBonusBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _claimDailyBonus,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎁 DAILY GIFT!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Claim ${TokenManager.DAILY_BONUS} tokens now!',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _currentMotivationalMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildSubjectsGrid() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.95, // Adjusted for better proportions
      children: [
        SubjectCard(
          title: 'Accounting',
          icon: Icons.account_balance,
          color: const Color(0xFF4285F4),
          description: 'Master financial principles',
          tokenCost: TokenManager.QUIZ_COST,
          onTap: () =>
              _startQuiz(context, 'Accounting', 'accounting_questions.json'),
        ),
        SubjectCard(
          title: 'Mathematics',
          icon: Icons.calculate,
          color: const Color(0xFF34A853),
          description: 'Solve complex equations',
          tokenCost: TokenManager.QUIZ_COST,
          onTap: () => _startQuiz(
            context,
            'Mathematics',
            'mathematics_questions.json',
          ),
        ),
        SubjectCard(
          title: 'Science',
          icon: Icons.science,
          color: const Color(0xFF9C27B0),
          description: 'Explore natural phenomena',
          tokenCost: TokenManager.QUIZ_COST,
          onTap: () =>
              _startQuiz(context, 'Science', 'science_questions.json'),
        ),
        SubjectCard(
          title: 'History',
          icon: Icons.history_edu,
          color: const Color(0xFFFF9800),
          description: 'Journey through time',
          tokenCost: TokenManager.QUIZ_COST,
          onTap: () =>
              _startQuiz(context, 'History', 'history_questions.json'),
        ),
      ],
    ),
  );
}



  void _startQuiz(BuildContext context, String subject, String fileName) async {
    // Check if user has enough tokens first
    final startResult = await TokenManager.instance.tryStartQuiz();

    if (!startResult.success) {
      _showInsufficientTokensDialog(startResult);
      return;
    }

    // If tokens were successfully deducted, show quiz settings
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return QuizSettingsBottomSheet(
          subject: subject,
          fileName: fileName,
          onQuizCompleted: (score, totalQuestions) =>
              _onQuizCompleted(subject, score, totalQuestions),
        );
      },
    ).then((_) {
      // Reload token data when bottom sheet closes
      _loadTokenData();
    });
  }

  void _showInsufficientTokensDialog(QuizStartResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.pink.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NOT ENOUGH TOKENS! 😱',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.grey[800],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'MAYBE LATER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showTokenShop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: Colors.amber.withOpacity(0.4),
                    ),
                    child: const Text(
                      'GET TOKENS! 💰',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Simplified Subject Card
class SubjectCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final int tokenCost;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.tokenCost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DuolingoStyleCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with consistent styling
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              
              const SizedBox(height: 16),
              
              // Title with consistent typography
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Description with consistent styling
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              
              const Spacer(),
              
              // Token cost with refined styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$tokenCost tokens',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Simplified Token Display
class TokenDisplay extends StatelessWidget {
  final int tokens;
  final VoidCallback onTap;

  const TokenDisplay({super.key, required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade400, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              '$tokens',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Duolingo-style pressable card widget (same as before)
class DuolingoStyleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration animationDuration;

  const DuolingoStyleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<DuolingoStyleCard> createState() => _DuolingoStyleCardState();
}

class _DuolingoStyleCardState extends State<DuolingoStyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              transform: Matrix4.identity()
                ..translate(0.0, 3.0 * _animationController.value),
              child: Opacity(
                opacity: 0.85 + (0.15 * (1 - _animationController.value)),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
