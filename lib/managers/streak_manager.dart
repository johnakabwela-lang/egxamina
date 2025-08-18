import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultsukulu/managers/token_manager.dart';
import 'package:ultsukulu/screens/quiz_game_screen.dart';

class StreakManager {
  static const String _lastCompletionDateKey = 'last_completion_date';
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _totalQuizzesKey = 'total_quizzes';
  static const String _subjectStreaksKey = 'subject_streaks';

  static StreakManager? _instance;
  static StreakManager get instance => _instance ??= StreakManager._();
  StreakManager._();

  // Get current overall streak
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentStreakKey) ?? 0;
  }

  // Get longest streak ever achieved
  Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestStreakKey) ?? 0;
  }

  // Get total quizzes completed
  Future<int> getTotalQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalQuizzesKey) ?? 0;
  }

  // Get streak for specific subject
  Future<int> getSubjectStreak(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectStreaks = prefs.getString(_subjectStreaksKey) ?? '{}';
    final Map<String, dynamic> streaks = Map<String, dynamic>.from(
      json.decode(subjectStreaks),
    );
    return streaks[subject] ?? 0;
  }

  // Mark quiz completion and update streaks
  Future<Map<String, int>> completeQuiz(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get last completion date
    final lastCompletionString = prefs.getString(_lastCompletionDateKey);
    DateTime? lastCompletion;
    if (lastCompletionString != null) {
      lastCompletion = DateTime.parse(lastCompletionString);
    }

    // Calculate streak
    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    if (lastCompletion == null) {
      // First time user
      currentStreak = 1;
    } else {
      final lastCompletionDay = DateTime(
        lastCompletion.year,
        lastCompletion.month,
        lastCompletion.day,
      );

      final daysDifference = today.difference(lastCompletionDay).inDays;

      if (daysDifference == 0) {
        // Same day - no streak change, but we still count the quiz
      } else if (daysDifference == 1) {
        // Consecutive day - increase streak
        currentStreak++;
      } else {
        // Streak broken - reset to 1
        currentStreak = 1;
      }
    }

    // Update overall stats
    await prefs.setString(_lastCompletionDateKey, today.toIso8601String());
    await prefs.setInt(_currentStreakKey, currentStreak);

    // Update longest streak if current is higher
    final longestStreak = await getLongestStreak();
    if (currentStreak > longestStreak) {
      await prefs.setInt(_longestStreakKey, currentStreak);
    }

    // Update total quizzes
    final totalQuizzes = await getTotalQuizzes();
    await prefs.setInt(_totalQuizzesKey, totalQuizzes + 1);

    // Update subject-specific streak
    await _updateSubjectStreak(subject);

    return {
      'currentStreak': currentStreak,
      'longestStreak': await getLongestStreak(),
      'totalQuizzes': totalQuizzes + 1,
      'subjectStreak': await getSubjectStreak(subject),
    };
  }

  // Update subject-specific streak
  Future<void> _updateSubjectStreak(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectStreaksString = prefs.getString(_subjectStreaksKey) ?? '{}';
    final Map<String, dynamic> subjectStreaks = Map<String, dynamic>.from(
      json.decode(subjectStreaksString),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get last completion for this subject
    final lastSubjectCompletionKey = '${subject}_last_completion';
    final lastCompletionString = prefs.getString(lastSubjectCompletionKey);

    int subjectStreak = subjectStreaks[subject] ?? 0;

    if (lastCompletionString == null) {
      subjectStreak = 1;
    } else {
      final lastCompletion = DateTime.parse(lastCompletionString);
      final lastCompletionDay = DateTime(
        lastCompletion.year,
        lastCompletion.month,
        lastCompletion.day,
      );

      final daysDifference = today.difference(lastCompletionDay).inDays;

      if (daysDifference == 0) {
        // Same day - no change
      } else if (daysDifference == 1) {
        // Consecutive day
        subjectStreak++;
      } else {
        // Reset
        subjectStreak = 1;
      }
    }

    subjectStreaks[subject] = subjectStreak;
    await prefs.setString(_subjectStreaksKey, json.encode(subjectStreaks));
    await prefs.setString(lastSubjectCompletionKey, today.toIso8601String());
  }

  // Check if streak is still active (not broken)
  Future<bool> isStreakActive() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompletionString = prefs.getString(_lastCompletionDateKey);

    if (lastCompletionString == null) return false;

    final lastCompletion = DateTime.parse(lastCompletionString);
    final lastCompletionDay = DateTime(
      lastCompletion.year,
      lastCompletion.month,
      lastCompletion.day,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysDifference = today.difference(lastCompletionDay).inDays;

    // Streak is active if last completion was today or yesterday
    return daysDifference <= 1;
  }

  // Reset all streaks (for testing or user preference)
  Future<void> resetAllStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCompletionDateKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_subjectStreaksKey);
    // Keep longest streak and total quizzes for historical data
  }

  // Get streak statistics for display
  Future<Map<String, dynamic>> getStreakStats() async {
    return {
      'currentStreak': await getCurrentStreak(),
      'longestStreak': await getLongestStreak(),
      'totalQuizzes': await getTotalQuizzes(),
      'isActive': await isStreakActive(),
    };
  }
}

class QuizSettingsBottomSheet extends StatefulWidget {
  final String subject;
  final String fileName;
  final void Function(int score, int totalQuestions)? onQuizCompleted;

  const QuizSettingsBottomSheet({
    super.key,
    required this.subject,
    required this.fileName,
    this.onQuizCompleted,
  });

  @override
  QuizSettingsBottomSheetState createState() => QuizSettingsBottomSheetState();
}

class QuizSettingsBottomSheetState extends State<QuizSettingsBottomSheet> {
  int selectedQuestionCount = 5;
  int selectedTimerDuration = 30;
  bool isLoading = false;
  String? errorMessage;
  int availableQuestions = 0;
  TextEditingController questionController = TextEditingController();
  TextEditingController timerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    questionController.text = selectedQuestionCount.toString();
    timerController.text = selectedTimerDuration.toString();
    _checkAvailableQuestions();
  }

  @override
  void dispose() {
    questionController.dispose();
    timerController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailableQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<Question> questions = await QuestionService.loadQuestions(
        widget.fileName,
      );
      setState(() {
        availableQuestions = questions.length;
        isLoading = false;
        if (selectedQuestionCount > availableQuestions) {
          selectedQuestionCount = availableQuestions;
          questionController.text = selectedQuestionCount.toString();
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = _getReadableErrorMessage(e.toString());
        availableQuestions = 0;
      });
    }
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('Unable to load asset')) {
      return 'Question file not found';
    } else if (error.contains('FormatException')) {
      return 'Invalid file format';
    } else if (error.contains('type')) {
      return 'Invalid data in file';
    } else {
      return 'Failed to load questions';
    }
  }

  void _validateQuestions(String value) {
    int? number = int.tryParse(value);
    if (number != null && number >= 1 && number <= availableQuestions) {
      setState(() {
        selectedQuestionCount = number;
      });
    }
  }

  void _validateTimer(String value) {
    int? number = int.tryParse(value);
    if (number != null && number >= 10 && number <= 300) {
      setState(() {
        selectedTimerDuration = number;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // Fixed height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle (visual only, not functional)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Text(
              '${widget.subject} Quiz Settings',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading questions...'),
            ] else if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checkAvailableQuestions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Questions Section
              _buildSettingCard(
                title: 'Number of Questions',
                subtitle: 'Available: $availableQuestions',
                child: Column(
                  children: [
                    TextField(
                      controller: questionController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Questions (1-$availableQuestions)',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: _validateQuestions,
                    ),
                    const SizedBox(height: 12),
                    // Quick select buttons
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 20, availableQuestions]
                          .where((count) => count <= availableQuestions)
                          .map(
                            (count) => _buildQuickButton(
                              label: count == availableQuestions
                                  ? 'All'
                                  : '$count',
                              isSelected: selectedQuestionCount == count,
                              onTap: () {
                                setState(() {
                                  selectedQuestionCount = count;
                                  questionController.text = count.toString();
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Timer Section
              _buildSettingCard(
                title: 'Timer per Question',
                subtitle: '10-300 seconds',
                child: Column(
                  children: [
                    TextField(
                      controller: timerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seconds (10-300)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: _validateTimer,
                    ),
                    const SizedBox(height: 12),
                    // Quick select buttons
                    Wrap(
                      spacing: 8,
                      children: [15, 30, 60, 120]
                          .map(
                            (seconds) => _buildQuickButton(
                              label: _formatTime(seconds),
                              isSelected: selectedTimerDuration == seconds,
                              onTap: () {
                                setState(() {
                                  selectedTimerDuration = seconds;
                                  timerController.text = seconds.toString();
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (selectedQuestionCount > 0 &&
                          selectedQuestionCount <= availableQuestions &&
                          selectedTimerDuration >= 10 &&
                          selectedTimerDuration <= 300)
                      ? () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizGameScreen(
                                subject: widget.subject,
                                questionCount: selectedQuestionCount,
                                fileName: widget.fileName,
                                timerDuration: selectedTimerDuration,
                              ),
                            ),
                          );
                          if (widget.onQuizCompleted != null) {
                            widget.onQuizCompleted!(0, selectedQuestionCount);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start Quiz',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],

            // Bottom padding for keyboard
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return remainingSeconds == 0
          ? '${minutes}m'
          : '${minutes}m ${remainingSeconds}s';
    }
  }
}

class TokenShopBottomSheet extends StatefulWidget {
  final VoidCallback onTokensUpdated;

  const TokenShopBottomSheet({super.key, required this.onTokensUpdated});

  @override
  _TokenShopBottomSheetState createState() => _TokenShopBottomSheetState();
}

class _TokenShopBottomSheetState extends State<TokenShopBottomSheet> {
  TokenStats? _tokenStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenStats();
  }

  Future<void> _loadTokenStats() async {
    final stats = await TokenManager.instance.getTokenStats();
    setState(() {
      _tokenStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _claimDailyBonus() async {
    final result = await TokenManager.instance.claimDailyBonus();

    if (result.success) {
      await _loadTokenStats();
      widget.onTokensUpdated();
      _showSuccessMessage(result.message);
    } else {
      _showErrorMessage(result.message);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Token Shop',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isLoading && _tokenStats != null)
                        Text(
                          'Current Balance: ${_tokenStats!.currentTokens} tokens',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading token information...'),
            ] else if (_tokenStats != null) ...[
              // Daily Bonus Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _tokenStats!.dailyBonusAvailable
                        ? [Colors.amber.shade100, Colors.amber.shade200]
                        : [Colors.grey.shade100, Colors.grey.shade200],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _tokenStats!.dailyBonusAvailable
                        ? Colors.amber.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _tokenStats!.dailyBonusAvailable
                              ? Colors.amber.shade700
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Bonus',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _tokenStats!.dailyBonusAvailable
                                      ? Colors.amber.shade800
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                _tokenStats!.dailyBonusAvailable
                                    ? 'Claim ${TokenManager.DAILY_BONUS} free tokens!'
                                    : 'Next bonus in ${_formatDuration(_tokenStats!.nextDailyBonus)}',
                                style: TextStyle(
                                  color: _tokenStats!.dailyBonusAvailable
                                      ? Colors.amber.shade700
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_tokenStats!.dailyBonusAvailable) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _claimDailyBonus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Claim Daily Bonus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // How to Earn Tokens Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to Earn Tokens',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEarnMethod(
                      'Daily Bonus',
                      '${TokenManager.DAILY_BONUS} tokens',
                      'Claim once per day',
                    ),
                    _buildEarnMethod(
                      'Quiz Completion',
                      '5-30 tokens',
                      'Based on your score',
                    ),
                    _buildEarnMethod(
                      'Streak Bonus',
                      '5+ tokens',
                      'Keep your daily streak alive',
                    ),
                    _buildEarnMethod(
                      'Perfect Score',
                      '30 tokens',
                      'Score 90% or higher',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Token Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Earned',
                            '${_tokenStats!.totalEarned}',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Spent',
                            '${_tokenStats!.totalSpent}',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnMethod(String title, String amount, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  '$amount - $description',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// QuizResultScreen moved to top-level
class QuizResultScreen extends StatefulWidget {
  final String subject;
  final int score;
  final int totalQuestions;
  final List<Question> questions;
  final List<int> userAnswers;
  final List<bool> correctAnswers;

  const QuizResultScreen({
    super.key,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
    required this.correctAnswers,
  });

  @override
  _QuizResultScreenState createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.score.toDouble())
        .animate(
          CurvedAnimation(parent: _scoreController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
      if (_getPercentage() >= 70) {
        _confettiController.forward();
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  double _getPercentage() {
    return (widget.score / widget.totalQuestions) * 100;
  }

  String _getPerformanceMessage() {
    double percentage = _getPercentage();
    if (percentage >= 90) return "Outstanding! 🏆";
    if (percentage >= 80) return "Excellent Work! 🌟";
    if (percentage >= 70) return "Well Done! 👏";
    if (percentage >= 60) return "Good Effort! 👍";
    if (percentage >= 50) return "Keep Practicing! 💪";
    return "Don't Give Up! 🎯";
  }

  Color _getPerformanceColor() {
    double percentage = _getPercentage();
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon() {
    double percentage = _getPercentage();
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 80) return Icons.star;
    if (percentage >= 70) return Icons.thumb_up;
    if (percentage >= 60) return Icons.sentiment_satisfied;
    if (percentage >= 50) return Icons.trending_up;
    return Icons.refresh;
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _confettiAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: ConfettiPainter(_confettiAnimation.value),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_getPerformanceColor().withOpacity(0.1), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Confetti overlay
            if (_getPercentage() >= 70) _buildConfetti(),

            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Score card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Performance icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _getPerformanceColor().withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getPerformanceIcon(),
                              size: 40,
                              color: _getPerformanceColor(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Performance message
                          Text(
                            _getPerformanceMessage(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Score display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              AnimatedBuilder(
                                animation: _scoreAnimation,
                                builder: (context, child) {
                                  return Text(
                                    _scoreAnimation.value.round().toString(),
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: _getPerformanceColor(),
                                    ),
                                  );
                                },
                              ),
                              Text(
                                '/${widget.totalQuestions}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Percentage
                          Text(
                            '${_getPercentage().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Progress bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _getPercentage() / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getPerformanceColor(),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Correct',
                            widget.score.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Incorrect',
                            (widget.totalQuestions - widget.score).toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Accuracy',
                            '${_getPercentage().toStringAsFixed(0)}%',
                            Colors.blue,
                            Icons.analytics,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Review section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assignment,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Question Review',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Question review list
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.questions.length,
                            itemBuilder: (context, index) {
                              return _buildQuestionReviewItem(index);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.replay, size: 20),
                            label: const Text(
                              'Take Quiz Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.home, size: 20),
                            label: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewItem(int index) {
    bool isCorrect = widget.correctAnswers[index];
    int userAnswer = widget.userAnswers[index];
    int correctAnswer = widget.questions[index].correctAnswer;
    bool wasAnswered = userAnswer != -1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.05)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCorrect
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.questions[index].question,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          if (!wasAnswered)
            Text(
              'No answer selected (Time up)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (!isCorrect) ...[
            Text(
              'Your answer: ${widget.questions[index].options[userAnswer]}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Correct answer: ${widget.questions[index].options[correctAnswer]}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for confetti effect moved to top-level
class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * progress;
      final color = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
      ][i % 5];

      paint.color = color.withOpacity(0.8);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
