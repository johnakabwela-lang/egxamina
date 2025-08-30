import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ultsukulu/models/question_model.dart' as game_screen;
import 'package:ultsukulu/screens/quiz_game_screen.dart' as game_screen;

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

// Add CreateMultiplayerQuizDialog widget
class CreateMultiplayerQuizDialog extends StatelessWidget {
  final String subject;
  final String fileName;

  const CreateMultiplayerQuizDialog({
    super.key,
    required this.subject,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Multiplayer Quiz'),
      content: Text('Multiplayer feature coming soon!'),
    );
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
  bool isMultiplayer = false;

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
      List<game_screen.Question> questions =
          await game_screen.QuestionService.loadQuestions(widget.fileName);
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

  void _startMultiplayerQuiz() {
    showDialog(
      context: context,
      builder: (context) => CreateMultiplayerQuizDialog(
        subject: widget.subject,
        fileName: widget.fileName,
      ),
    );
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

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.teal.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? Colors.teal : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.teal : Colors.grey.shade800,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

            // Mode selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.person,
                    label: 'Single Player',
                    selected: !isMultiplayer,
                    onTap: () => setState(() => isMultiplayer = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.groups,
                    label: 'Play with Group',
                    selected: isMultiplayer,
                    onTap: () {
                      setState(() => isMultiplayer = true);
                      _startMultiplayerQuiz();
                    },
                  ),
                ),
              ],
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
                              builder: (context) => game_screen.QuizGameScreen(
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
