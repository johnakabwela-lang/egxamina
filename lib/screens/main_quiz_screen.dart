// Mobile-optimized QuizScreen with education color scheme
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ultsukulu/managers/streak_manager.dart';
import 'package:ultsukulu/managers/token_manager.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

import 'package:ultsukulu/screens/shop_screen.dart';

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
  List<String> _clozeFiles = [];

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
    _loadClozeFiles();
  }

  Future<void> _loadClozeFiles() async {
    try {
      // Load the list of cloze files from assets
      final manifestContent = await DefaultAssetBundle.of(
        context,
      ).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter files that are in the english cloze directory
      final clozeFiles = manifestMap.keys
          .where(
            (String key) =>
                key.startsWith('assets/questions/english/') &&
                key.endsWith('.json'),
          )
          .toList();

      setState(() {
        _clozeFiles = clozeFiles;
      });
    } catch (e) {
      print('Error loading cloze files: $e');
      // Fallback with some default files
      setState(() {
        _clozeFiles = [
          'assets/questions/english/2019.json',
          'assets/questions/english/2022.json',
          'assets/questions/english/2025Paraddroid.json',
        ];
      });
    }
  }

  String _getRandomClozeFile() {
    if (_clozeFiles.isEmpty) return 'assets/questions/english/2019.json';
    final random = Random();
    return _clozeFiles[random.nextInt(_clozeFiles.length)];
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🎉 DAILY BONUS! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                child: const Text(
                  'AWESOME! 🚀',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTokenShop() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TokenShopScreen(onTokensUpdated: _loadTokenData),
      ),
    );
  }

  void _showStreakCelebration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '🔥 STREAK MASTER! 🔥',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re unstoppable!\n$_currentStreak days and counting!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: Colors.orange.withOpacity(0.3),
                ),
                child: const Text(
                  'KEEP GOING! 💪',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
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
      backgroundColor: Colors.blue.shade600, // Education blue background
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // App logo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.school, color: Colors.blue.shade600, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ISUKULU',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Token display
          TokenDisplayer(tokens: _currentTokens, onTap: _showTokenShop),
          // Streak display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: _isStreakActive ? Colors.orange.shade600 : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_currentStreak',
                  style: TextStyle(
                    color: _isStreakActive
                        ? Colors.orange.shade600
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _claimDailyBonus,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎁 DAILY GIFT!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Claim ${TokenManager.DAILY_BONUS} tokens now!',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentMotivationalMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1, // Optimized for mobile
        children: [
          SubjectCard(
            title: 'Accounting',
            icon: Icons.account_balance,
            color: Colors.blue.shade600,
            tokenCost: TokenManager.QUIZ_COST,
            onTap: () =>
                _startQuiz(context, 'Accounting', 'accounting_questions.json'),
          ),
          SubjectCard(
            title: 'Mathematics',
            icon: Icons.calculate,
            color: Colors.blue.shade500,
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
            color: Colors.blue.shade700,
            tokenCost: TokenManager.QUIZ_COST,
            onTap: () =>
                _startQuiz(context, 'Science', 'science_questions.json'),
          ),
          SubjectCard(
            title: 'History',
            icon: Icons.history_edu,
            color: Colors.blue.shade400,
            tokenCost: TokenManager.QUIZ_COST,
            onTap: () =>
                _startQuiz(context, 'History', 'history_questions.json'),
          ),
          // English subject card with mode selection
          SubjectCard(
            title: 'English',
            icon: Icons.language,
            color: Colors.green.shade600,
            tokenCost: TokenManager.QUIZ_COST,
            onTap: () => _showEnglishModeSelection(),
          ),
        ],
      ),
    );
  }

  void _showEnglishModeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Choose English Mode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 24),

                // Mode options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // General Quiz Mode
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _startQuiz(
                            context,
                            'English',
                            'english_questions.json',
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.quiz,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'General Quiz',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Multiple choice questions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Cloze Passage Mode
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _startClozeQuiz(
                            context,
                            'English Cloze',
                            _getRandomClozeFile(),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.text_fields,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cloze Passage',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fill in the missing words',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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

  void _startClozeQuiz(
    BuildContext context,
    String subject,
    String fileName,
  ) async {
    // Check if user has enough tokens first
    final startResult = await TokenManager.instance.tryStartQuiz();

    if (!startResult.success) {
      _showInsufficientTokensDialog(startResult);
      return;
    }

    // If tokens were successfully deducted, show cloze quiz settings
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ClozeQuizSettingsBottomSheet(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NOT ENOUGH TOKENS! 😱',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'MAYBE LATER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showTokenShop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: Colors.blue.withOpacity(0.3),
                    ),
                    child: const Text(
                      'GET TOKENS! 💰',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

// Simplified Subject Card - Mobile optimized
class SubjectCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int tokenCost;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Token cost
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: color, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$tokenCost',
                      style: TextStyle(
                        fontSize: 11,
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

// Duolingo-style pressable card widget
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
                ..translate(0.0, 2.0 * _animationController.value),
              child: Opacity(
                opacity: 0.9 + (0.1 * (1 - _animationController.value)),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ClozeQuizSettingsBottomSheet extends StatefulWidget {
  final String subject;
  final String fileName;
  final Function(int score, int totalQuestions) onQuizCompleted;

  const ClozeQuizSettingsBottomSheet({
    super.key,
    required this.subject,
    required this.fileName,
    required this.onQuizCompleted,
  });

  @override
  State<ClozeQuizSettingsBottomSheet> createState() =>
      _ClozeQuizSettingsBottomSheetState();
}

class _ClozeQuizSettingsBottomSheetState
    extends State<ClozeQuizSettingsBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic>? _clozeData;
  int _selectedBlanks = 10;
  int _selectedMinutes = 5; // Default to 5 minutes
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final List<int> _blankOptions = [5, 10, 15, 20];
  final List<int> _timeOptions = [1, 2, 3, 5, 7, 10, 14]; // Minutes

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadClozeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClozeData() async {
    setState(() => _isLoading = true);

    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString(widget.fileName);
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _clozeData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load cloze passage: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startClozeQuiz() {
    if (_clozeData == null) return;

    HapticFeedback.mediumImpact();

    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ClozeQuizScreen(
              subject: widget.subject,
              clozeData: _clozeData!,
              maxBlanks: _selectedBlanks,
              timeLimit: Duration(minutes: _selectedMinutes),
              onQuizCompleted: widget.onQuizCompleted,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 300),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 100),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'Loading cloze passage...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 100),
                  ] else ...[
                    // Header
                    _buildHeader(),

                    // Preview section
                    if (_clozeData != null) _buildPreviewSection(),

                    // Settings
                    _buildSettingsSection(),

                    // Start button
                    _buildStartButton(),

                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.text_fields, color: Colors.white, size: 28),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            widget.subject,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Fill in the missing words',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    final String reference = _clozeData!['reference'] ?? 'Unknown';
    final String passage = _clozeData!['passage'] ?? '';
    final String previewText = passage.length > 150
        ? '${passage.substring(0, 150)}...'
        : passage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: Colors.teal.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'Reference: $reference',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            previewText.replaceAllMapped(
              RegExp(r'\(\d+\)'),
              (match) => '_____',
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Number of blanks selector
          _buildBlanksSelector(),

          const SizedBox(height: 20),

          // Time limit selector
          _buildTimeSelector(),
        ],
      ),
    );
  }

  Widget _buildBlanksSelector() {
    final totalBlanks = _clozeData?['blanks']?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            Text(
              'Number of Blanks (Total: $totalBlanks)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _blankOptions.map((count) {
            final isSelected = count == _selectedBlanks;
            final isAvailable = count <= totalBlanks;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() => _selectedBlanks = count);
                      HapticFeedback.lightImpact();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? Colors.grey.shade200
                      : isSelected
                      ? Colors.teal.shade500
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !isAvailable
                        ? Colors.grey.shade300
                        : isSelected
                        ? Colors.teal.shade500
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$count blanks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: !isAvailable
                        ? Colors.grey.shade400
                        : isSelected
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            const Text(
              'Time Limit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeOptions.map((minutes) {
            final isSelected = minutes == _selectedMinutes;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedMinutes = minutes);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orange.shade500
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange.shade500
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$minutes min${minutes > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final canStart = _clozeData != null && !_isLoading;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: canStart ? _startClozeQuiz : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade500,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: canStart ? 6 : 0,
            shadowColor: Colors.teal.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canStart) ...[
                const Icon(Icons.play_arrow, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'START CLOZE QUIZ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ] else ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LOADING...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ClozeQuizScreen extends StatefulWidget {
  final String subject;
  final Map<String, dynamic> clozeData;
  final int maxBlanks;
  final Duration timeLimit;
  final Function(int score, int totalQuestions) onQuizCompleted;

  const ClozeQuizScreen({
    super.key,
    required this.subject,
    required this.clozeData,
    required this.maxBlanks,
    required this.timeLimit,
    required this.onQuizCompleted,
  });

  @override
  State<ClozeQuizScreen> createState() => _ClozeQuizScreenState();
}

class _ClozeQuizScreenState extends State<ClozeQuizScreen> {
  late List<int> _selectedBlankNumbers;
  late Map<String, dynamic> _blanks;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _answerStatus = {};
  bool _showResults = false;
  int _score = 0;

  // Timer related
  late Timer _timer;
  late Duration _remainingTime;
  bool _isTimeUp = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timeLimit;
    _initializeQuiz();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        timer.cancel();
        setState(() => _isTimeUp = true);
        _finishQuiz();
      }
    });
  }

  void _initializeQuiz() {
    _blanks = widget.clozeData['blanks'] ?? {};
    final allBlankNumbers = _blanks.keys.map((key) => int.parse(key)).toList();
    allBlankNumbers.sort();

    final random = Random();
    if (allBlankNumbers.length > widget.maxBlanks) {
      allBlankNumbers.shuffle(random);
      _selectedBlankNumbers = allBlankNumbers.take(widget.maxBlanks).toList();
      _selectedBlankNumbers.sort();
    } else {
      _selectedBlankNumbers = allBlankNumbers;
    }

    for (int blankNum in _selectedBlankNumbers) {
      _controllers[blankNum] = TextEditingController();
    }
  }

  void _finishQuiz() {
    if (_showResults) return;

    _timer.cancel();

    // Calculate score based on current answers
    _score = 0;
    for (int blankNum in _selectedBlankNumbers) {
      final controller = _controllers[blankNum]!;
      final userAnswer = controller.text.trim().toLowerCase();

      if (userAnswer.isNotEmpty) {
        final blankData = _blanks[blankNum.toString()];
        final correctWord = (blankData['word'] as String).toLowerCase();
        final synonyms =
            (blankData['synonyms'] as List<dynamic>?)
                ?.map((s) => s.toString().toLowerCase())
                .toList() ??
            [];

        final isCorrect =
            userAnswer == correctWord || synonyms.contains(userAnswer);
        _answerStatus[blankNum] = isCorrect;
        if (isCorrect) _score++;
      } else {
        _answerStatus[blankNum] = false;
      }
    }

    setState(() => _showResults = true);
    widget.onQuizCompleted(_score, _selectedBlankNumbers.length);
  }

  String _formatTime(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.subject} - Cloze Quiz',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Timer display
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingTime.inSeconds < 60
                  ? Colors.red.shade600
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _finishQuiz,
            child: const Text(
              'FINISH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: _buildPassageWithInputs(),
          ),
        ),
      ),
    );
  }

  Widget _buildPassageWithInputs() {
    final passage = widget.clozeData['passage'] as String;
    final List<Widget> widgets = [];
    final regex = RegExp(r'\((\d+)\)');
    int lastEnd = 0;

    for (Match match in regex.allMatches(passage)) {
      if (match.start > lastEnd) {
        widgets.add(
          Text(
            passage.substring(lastEnd, match.start),
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      }

      final blankNumber = int.parse(match.group(1)!);

      if (_selectedBlankNumbers.contains(blankNumber)) {
        widgets.add(_buildBlankInput(blankNumber));
      } else {
        final blankData = _blanks[blankNumber.toString()];
        final correctWord = blankData?['word'] ?? '_____';
        widgets.add(
          Text(
            correctWord,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey.shade500,
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < passage.length) {
      widgets.add(
        Text(
          passage.substring(lastEnd),
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Wrap(
      children: widgets,
      crossAxisAlignment: WrapCrossAlignment.center,
    );
  }

  Widget _buildBlankInput(int blankNum) {
    final controller = _controllers[blankNum]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 150),
          child: TextField(
            controller: controller,
            enabled: !_isTimeUp,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.teal.shade500, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              filled: true,
              fillColor: _isTimeUp ? Colors.grey.shade100 : Colors.white,
              hintText: '($blankNum)',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / _selectedBlankNumbers.length * 100).round();
    final timeUsed = widget.timeLimit - _remainingTime;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: percentage >= 70
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : percentage >= 50
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _isTimeUp ? 'Time\'s Up!' : 'Quiz Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'You scored $_score out of ${_selectedBlankNumbers.length}',
                style: TextStyle(fontSize: 18, color: Colors.teal.shade600),
              ),

              const SizedBox(height: 8),

              Text(
                'Time: ${_formatTime(timeUsed)}',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAnswersDialog(),
                      icon: const Icon(Icons.visibility),
                      label: const Text('VIEW ANSWERS (15 TOKENS)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'BACK TO MENU',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnswersDialog() async {
    final tokenManager = TokenManager.instance;
    const int answersCost = 15;

    // Check if user has enough tokens
    final hasEnoughTokens = await tokenManager.hasEnoughTokens(answersCost);

    if (!hasEnoughTokens) {
      final currentTokens = await tokenManager.getTokens();
      _showInsufficientTokensDialog(currentTokens, answersCost);
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.stars, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('View Answers'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will cost $answersCost tokens to view all correct answers and explanations.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: Colors.amber.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$answersCost Tokens',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await tokenManager.spendTokens(
                answersCost,
                reason: 'View quiz answers',
              );
              if (success) {
                _showAnswersBottomSheet();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Answers'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientTokensDialog(int currentTokens, int required) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Insufficient Tokens'),
          ],
        ),
        content: Text(
          'You need $required tokens to view answers, but you only have $currentTokens tokens. Complete more quizzes or claim your daily bonus to earn more tokens!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAnswersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.quiz, color: Colors.teal.shade600, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Answer Key',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Answers list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _selectedBlankNumbers.length,
                itemBuilder: (context, index) {
                  final blankNum = _selectedBlankNumbers[index];
                  final blankData = _blanks[blankNum.toString()];
                  final correctWord = blankData['word'] as String;
                  final synonyms =
                      (blankData['synonyms'] as List<dynamic>?)
                          ?.map((s) => s.toString())
                          .toList() ??
                      [];
                  final explanation = blankData['explanation'] as String?;

                  final userAnswer = _controllers[blankNum]?.text.trim() ?? '';
                  final isCorrect = _answerStatus[blankNum] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and status
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Blank $blankNum',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                              size: 20,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // User's answer
                        if (userAnswer.isNotEmpty) ...[
                          Text(
                            'Your answer: $userAnswer',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCorrect
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Correct answer
                        Text(
                          'Correct answer: $correctWord',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),

                        // Synonyms
                        if (synonyms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Also accepted: ${synonyms.join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],

                        // Explanation
                        if (explanation != null && explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Explanation',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  explanation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
