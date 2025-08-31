import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../models/question_model.dart';
import '../services/auth_service.dart';
import 'quiz_result_screen.dart';
import '../widgets/play_with_group_dialog.dart';

class QuizGameScreen extends StatefulWidget {
  final String subject;
  final int questionCount;
  final String fileName;
  final int timerDuration;

  const QuizGameScreen({
    super.key,
    required this.subject,
    required this.questionCount,
    required this.fileName,
    required this.timerDuration,
  });

  @override
  QuizGameScreenState createState() => QuizGameScreenState();

  // Helper method to show play with group dialog
  static Future<void> showPlayWithGroupDialog(
    BuildContext context, {
    required String subject,
    required String fileName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PlayWithGroupDialog(
        subject: subject,
        fileName: fileName,
        groupId:
            '', // Add an empty string or get a proper group ID from somewhere
      ),
    );
  }
}

// Independent Options Card Widget
class PressEffectedWidget extends StatelessWidget {
  final String option;
  final String optionLabel;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final bool timeUp;
  final bool isPressed;
  final VoidCallback onTap;
  final Animation<double> shakeAnimation;
  final Animation<double> buttonPressAnimation;
  final bool isSmallScreen;

  const PressEffectedWidget({
    super.key,
    required this.option,
    required this.optionLabel,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.timeUp,
    required this.isPressed,
    required this.onTap,
    required this.shakeAnimation,
    required this.buttonPressAnimation,
    this.isSmallScreen = false,
  });

  Color _getBackgroundColor() {
    if (!isAnswered && !timeUp) {
      return isPressed ? const Color(0xFFE8F4FD) : Colors.white;
    }

    if (isCorrect) {
      return const Color(0xFF58CC02).withAlpha(26); // 0.1 * 255
    } else if (isSelected) {
      return const Color(0xFFE74C3C).withAlpha(26); // 0.1 * 255
    }

    return Colors.white.withAlpha(153); // 0.6 * 255
  }

  Color _getBorderColor() {
    if (!isAnswered && !timeUp) {
      return isPressed ? const Color(0xFF1CB0F6) : const Color(0xFFE5E5E5);
    }

    if (isCorrect) {
      return const Color(0xFF58CC02);
    } else if (isSelected) {
      return const Color(0xFFE74C3C);
    }

    return const Color(0xFFE5E5E5);
  }

  Color _getTextColor() {
    if (!isAnswered && !timeUp) {
      return const Color(0xFF4B4B4B);
    }

    if (isCorrect) {
      return const Color(0xFF58CC02);
    } else if (isSelected) {
      return const Color(0xFFE74C3C);
    }

    return const Color(0xFF777777);
  }

  Widget _getStatusIcon() {
    if (!isAnswered && !timeUp) return const SizedBox.shrink();

    if (isCorrect) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF58CC02),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: isSmallScreen ? 16 : 18,
        ),
      );
    } else if (isSelected) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFFE74C3C),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          color: Colors.white,
          size: isSmallScreen ? 16 : 18,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return AnimatedBuilder(
      animation: Listenable.merge([shakeAnimation, buttonPressAnimation]),
      builder: (context, child) {
        double shakeOffset = 0;
        double pressOffset = 0;

        if (isSelected && !isCorrect && (isAnswered || timeUp)) {
          shakeOffset = shakeAnimation.value;
        }

        if (isPressed) {
          pressOffset = buttonPressAnimation.value;
        }

        return Transform.translate(
          offset: Offset(shakeOffset, -pressOffset),
          child: GestureDetector(
            onTap: (isAnswered || timeUp) ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                bottom: isSmallScreen ? 4 : 8,
                left: pressOffset > 0 ? pressOffset : 0,
                right: pressOffset > 0 ? pressOffset : 0,
              ),
              padding: EdgeInsets.all(
                isTablet ? 20 : (isSmallScreen ? 14 : 16),
              ),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                border: Border.all(
                  color: _getBorderColor(),
                  width: (isAnswered || timeUp) ? 2 : 1.5,
                ),
                boxShadow: [
                  if (!isAnswered && !timeUp)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: isPressed ? 2 : 8,
                      offset: Offset(0, isPressed ? 1 : 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Option label (A, B, C, D)
                  Container(
                    width: isSmallScreen ? 28 : 32,
                    height: isSmallScreen ? 28 : 32,
                    decoration: BoxDecoration(
                      color: _getBorderColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 6 : 8,
                      ),
                      border: Border.all(
                        color: _getBorderColor().withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        optionLabel,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: isSmallScreen ? 12 : 16),

                  // Option text
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(),
                        height: 1.3,
                      ),
                      maxLines: isSmallScreen ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: isSmallScreen ? 8 : 12),

                  // Status icon
                  _getStatusIcon(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Streak Widget
class QuizStreakWidget extends StatefulWidget {
  final int streakCount;

  const QuizStreakWidget({super.key, required this.streakCount});

  @override
  State<QuizStreakWidget> createState() => _QuizStreakWidgetState();
}

class _QuizStreakWidgetState extends State<QuizStreakWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(QuizStreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakCount > oldWidget.streakCount && widget.streakCount >= 2) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getStreakEmoji() {
    if (widget.streakCount >= 10) return "💯";
    if (widget.streakCount >= 7) return "⚡";
    if (widget.streakCount >= 5) return "🔥";
    if (widget.streakCount >= 3) return "🌟";
    return "✨";
  }

  String _getStreakText() {
    if (widget.streakCount >= 10) return "LEGENDARY!";
    if (widget.streakCount >= 7) return "AMAZING!";
    if (widget.streakCount >= 5) return "ON FIRE!";
    if (widget.streakCount >= 3) return "GREAT STREAK!";
    if (widget.streakCount >= 2) return "NICE!";
    return "";
  }

  Color _getStreakColor() {
    if (widget.streakCount >= 10) return const Color(0xFF9B59B6);
    if (widget.streakCount >= 7) return const Color(0xFFE67E22);
    if (widget.streakCount >= 5) return const Color(0xFFE74C3C);
    if (widget.streakCount >= 3) return const Color(0xFFFF9500);
    return const Color(0xFF58CC02);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakCount < 2) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_getStreakColor(), _getStreakColor().withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStreakColor().withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    _getStreakEmoji(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStreakText(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.streakCount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'in a row',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  bool isAnswered = false;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _buttonPressAnimation;
  List<int> userAnswers = [];
  List<bool> correctAnswers = [];

  Timer? _questionTimer;
  Timer? _autoNextTimer;
  int remainingTime = 0;
  bool timeUp = false;
  bool showConfetti = false;
  int streakCount = 0;
  int pressedButtonIndex = -1;

  // Whether the user can create multiplayer sessions
  bool get _canPlayWithGroup =>
      AuthService.isSignedIn && // User must be signed in
      !isAnswered && // Can't start group play after answering
      currentQuestionIndex == 0; // Can only start at beginning of quiz

  // Audio player for sound effects
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    remainingTime = widget.timerDuration;

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: Duration(seconds: widget.timerDuration),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonPressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shakeAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _buttonPressAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeOut),
    );

    _loadQuestions();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _buttonPressController.dispose();
    _questionTimer?.cancel();
    _autoNextTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Sound effect methods
  Future<void> _playCorrectSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      // Ignore sound errors to avoid disrupting gameplay
      debugPrint('Failed to play correct sound: $e');
    }
  }

  Future<void> _playWrongSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      // Ignore sound errors to avoid disrupting gameplay
      debugPrint('Failed to play wrong sound: $e');
    }
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      List<Question> allQuestions = await QuestionService.loadQuestions(
        widget.fileName,
      );

      if (allQuestions.isEmpty) {
        throw Exception('No questions found for ${widget.subject}');
      }

      allQuestions.shuffle(Random());
      questions = allQuestions.take(widget.questionCount).toList();

      for (var question in questions) {
        question.shuffleOptions();
      }

      userAnswers = List.filled(questions.length, -1);
      correctAnswers = List.filled(questions.length, false);

      setState(() {
        isLoading = false;
      });

      _fadeController.forward();
      _startTimer();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load questions: ${e.toString()}';
      });
    }
  }

  void _startTimer() {
    _timerController.reset();
    _timerController.forward();

    setState(() {
      remainingTime = widget.timerDuration;
      timeUp = false;
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime--;
      });

      if (remainingTime <= 10 && remainingTime > 0) {
        _pulseController.repeat(reverse: true);
      }

      if (remainingTime <= 0) {
        timer.cancel();
        _pulseController.stop();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    if (!isAnswered) {
      setState(() {
        timeUp = true;
        isAnswered = true;
        selectedAnswer = -1;
        userAnswers[currentQuestionIndex] = -1;
        correctAnswers[currentQuestionIndex] = false;
        streakCount = 0;
      });

      HapticFeedback.heavyImpact();
      _playWrongSound(); // Play wrong sound for timeout

      // Show snackbar for time up
      _showTimeUpSnackbar();

      _autoNextTimer = Timer(const Duration(seconds: 4), () {
        _nextQuestion();
      });
    }
  }

  void _showTimeUpSnackbar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Time\'s Up! ⏰',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'You ran out of time for this question',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _selectAnswer(int answerIndex) async {
    if (!isAnswered && !timeUp) {
      setState(() {
        pressedButtonIndex = answerIndex;
      });

      _buttonPressController.forward().then((_) {
        _buttonPressController.reverse();
      });

      await Future.delayed(const Duration(milliseconds: 100));

      _questionTimer?.cancel();
      _pulseController.stop();

      bool isCorrect =
          answerIndex == questions[currentQuestionIndex].correctAnswer;

      setState(() {
        selectedAnswer = answerIndex;
        isAnswered = true;
        userAnswers[currentQuestionIndex] = answerIndex;
        correctAnswers[currentQuestionIndex] = isCorrect;
        pressedButtonIndex = -1;

        if (isCorrect) {
          score++;
          streakCount++;
          if (streakCount >= 3) {
            showConfetti = true;
          }
        } else {
          streakCount = 0;
        }
      });

      if (isCorrect) {
        _playCorrectSound(); // Play correct sound
        if (streakCount >= 3) {}
        HapticFeedback.mediumImpact();
        _pulseController.forward().then((_) => _pulseController.reset());
      } else {
        // Wrong answer sound with 0.7s delay
        Timer(const Duration(milliseconds: 700), () {
          _playWrongSound();
        });

        HapticFeedback.heavyImpact();
        _shakeController.repeat(reverse: true);
        Timer(const Duration(milliseconds: 600), () {
          _shakeController.stop();
          _shakeController.reset();
        });
      }

      _autoNextTimer = Timer(const Duration(seconds: 4), () {
        _nextQuestion();
      });
    }
  }

  void _nextQuestion() {
    _autoNextTimer?.cancel();
    _questionTimer?.cancel();

    // Clear any existing snackbars when moving to next question
    ScaffoldMessenger.of(context).clearSnackBars();

    if (currentQuestionIndex < questions.length - 1) {
      _fadeController.reset();
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        isAnswered = false;
        timeUp = false;
        showConfetti = false;
      });
      _fadeController.forward();
      _startTimer();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          subject: widget.subject,
          score: score,
          totalQuestions: questions.length,
          questions: questions,
          userAnswers: userAnswers,
          correctAnswers: correctAnswers,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (remainingTime <= 5) return const Color(0xFFE74C3C);
    if (remainingTime <= 10) return const Color(0xFFFF9500);
    return const Color(0xFF58CC02);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isTablet = screenSize.width > 600;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: Text(
            '${widget.subject} Quiz',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4B4B),
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF4B4B4B),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F7F7), Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF58CC02),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading Questions...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B4B4B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait while we prepare your quiz',
                  style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: Text('${widget.subject} Quiz'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF4B4B4B),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F7F7), Colors.white],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B4B4B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadQuestions,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF58CC02)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(color: Color(0xFF58CC02)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: Text('${widget.subject} Quiz'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF4B4B4B),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 64, color: Color(0xFF777777)),
              SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(fontSize: 18, color: Color(0xFF777777)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 80 : 90),
        child: Stack(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: const Color(0xFF4B4B4B),
              centerTitle: false,
              automaticallyImplyLeading: false,
              toolbarHeight: isSmallScreen ? 80 : 90,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Top row with indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Streak indicator
                          if (_canPlayWithGroup)
                            OutlinedButton.icon(
                              onPressed: () {
                                QuizGameScreen.showPlayWithGroupDialog(
                                  context,
                                  subject: widget.subject,
                                  fileName: widget.fileName,
                                );
                              },
                              icon: const Icon(Icons.group_add),
                              label: const Text('Play with Group'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF58CC02),
                                side: const BorderSide(
                                  color: Color(0xFF58CC02),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          if (!_canPlayWithGroup)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: streakCount >= 3
                                    ? const Color(0xFFFF9500).withOpacity(0.1)
                                    : const Color(0xFF777777).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: streakCount >= 3
                                      ? const Color(0xFFFF9500).withOpacity(0.3)
                                      : const Color(
                                          0xFF777777,
                                        ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: isSmallScreen ? 14 : 16,
                                    color: streakCount >= 3
                                        ? const Color(0xFFFF9500)
                                        : const Color(0xFF777777),
                                  ),
                                  SizedBox(width: isSmallScreen ? 2 : 4),
                                  Text(
                                    '$streakCount',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: streakCount >= 3
                                          ? const Color(0xFFFF9500)
                                          : const Color(0xFF777777),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Timer
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: remainingTime <= 10
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 6 : 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTimerColor().withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getTimerColor().withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        timeUp ? Icons.timer_off : Icons.timer,
                                        color: _getTimerColor(),
                                        size: isSmallScreen ? 14 : 16,
                                      ),
                                      SizedBox(width: isSmallScreen ? 2 : 4),
                                      Text(
                                        timeUp
                                            ? 'Time Up!'
                                            : _formatTime(remainingTime),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: _getTimerColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Score
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF58CC02).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '$score/${currentQuestionIndex + (isAnswered ? 1 : 0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF58CC02),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress indicator and question number
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E5E5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                widthFactor:
                                    (currentQuestionIndex + 1) /
                                    questions.length,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF58CC02),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${currentQuestionIndex + 1}/${questions.length}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Timer progress bar as bottom border
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  return Container(
                    height: 3,
                    color: const Color(0xFFE5E5E5),
                    child: FractionallySizedBox(
                      widthFactor: timeUp
                          ? 0.0
                          : (1.0 - _timerController.value),
                      alignment: Alignment.centerLeft,
                      child: Container(color: _getTimerColor()),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F7F7), Colors.white],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 24 : 16,
              isTablet ? 24 : 16,
              isTablet ? 24 : 16,
              0, // Remove bottom padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question card with dynamic height based on content
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Question header - only show reference if exists
                      if (questions[currentQuestionIndex].reference != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E44AD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF8E44AD,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bookmark_outline,
                                    size: 12,
                                    color: Color(0xFF8E44AD),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    questions[currentQuestionIndex].reference!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8E44AD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Question text - only show if it exists and is not empty
                      if (questions[currentQuestionIndex].question.isNotEmpty)
                        Text(
                          questions[currentQuestionIndex].question,
                          style: TextStyle(
                            fontSize: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),

                      // Question image - only build if image exists
                      if (questions[currentQuestionIndex].imagePath !=
                          null) ...[
                        SizedBox(
                          height:
                              questions[currentQuestionIndex]
                                  .question
                                  .isNotEmpty
                              ? 16
                              : 0,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            questions[currentQuestionIndex].imagePath!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: isSmallScreen ? 120 : 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Color(0xFF777777),
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                // Options section - Expanded to fill remaining space
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemCount: questions[currentQuestionIndex].options.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: isSmallScreen ? 12 : 16),
                    itemBuilder: (context, index) {
                      bool isCorrect =
                          index ==
                          questions[currentQuestionIndex].correctAnswer;
                      bool isSelected = index == selectedAnswer;
                      bool isPressed = index == pressedButtonIndex;

                      return MultilineOptionButton(
                        option: questions[currentQuestionIndex].options[index],
                        optionLabel: String.fromCharCode(65 + index),
                        isSelected: isSelected,
                        isCorrect: isCorrect,
                        isAnswered: isAnswered,
                        timeUp: timeUp,
                        isPressed: isPressed,
                        onTap: () => _selectAnswer(index),
                        shakeAnimation: _shakeAnimation,
                        buttonPressAnimation: _buttonPressAnimation,
                        isSmallScreen: isSmallScreen,
                        isTablet: isTablet,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Question class moved to models/question_model.dart

// New MultilineOptionButton widget to handle multiline text properly
class MultilineOptionButton extends StatelessWidget {
  final String option;
  final String optionLabel;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final bool timeUp;
  final bool isPressed;
  final VoidCallback onTap;
  final Animation<double> shakeAnimation;
  final Animation<double> buttonPressAnimation;
  final bool isSmallScreen;
  final bool isTablet;

  const MultilineOptionButton({
    super.key,
    required this.option,
    required this.optionLabel,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.timeUp,
    required this.isPressed,
    required this.onTap,
    required this.shakeAnimation,
    required this.buttonPressAnimation,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (isAnswered || timeUp) {
      if (isCorrect) {
        backgroundColor = const Color(0xFF58CC02);
        borderColor = const Color(0xFF58CC02);
        textColor = Colors.white;
        icon = Icons.check_circle;
      } else if (isSelected) {
        backgroundColor = const Color(0xFFFF4B4B);
        borderColor = const Color(0xFFFF4B4B);
        textColor = Colors.white;
        icon = Icons.cancel;
      } else {
        backgroundColor = const Color(0xFFF7F7F7);
        borderColor = const Color(0xFFE5E5E5);
        textColor = const Color(0xFF4B4B4B);
      }
    } else if (isSelected) {
      backgroundColor = const Color(0xFF1CB0F6).withOpacity(0.1);
      borderColor = const Color(0xFF1CB0F6);
      textColor = const Color(0xFF1CB0F6);
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFE5E5E5);
      textColor = const Color(0xFF4B4B4B);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([shakeAnimation, buttonPressAnimation]),
      builder: (context, child) {
        double scale = isPressed ? 0.98 : 1.0;
        double translateX = (isSelected && (isAnswered || timeUp) && !isCorrect)
            ? shakeAnimation.value * 10
            : 0;

        return Transform.translate(
          offset: Offset(translateX, 0),
          child: Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: (isAnswered || timeUp) ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 18 : 16,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Option label (A, B, C, D)
                    Container(
                      width: isTablet ? 32 : 28,
                      height: isTablet ? 32 : 28,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: isTablet ? 16 : 12),

                    // Option text - flexible to handle multiline
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: isTablet ? 16 : (isSmallScreen ? 14 : 15),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible,
                      ),
                    ),

                    // Status icon
                    if (icon != null) ...[
                      SizedBox(width: isTablet ? 12 : 8),
                      Icon(icon, color: Colors.white, size: isTablet ? 24 : 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuestionService {
  static Future<List<Question>> loadQuestions(String fileName) async {
    try {
      String assetPath = 'assets/questions/$fileName';
      String jsonString = await rootBundle.loadString(assetPath);
      List<dynamic> jsonList = json.decode(jsonString);

      if (jsonList.isEmpty) {
        throw Exception('Question file is empty');
      }

      List<Question> questions = [];

      for (int i = 0; i < jsonList.length; i++) {
        try {
          Map<String, dynamic> questionJson =
              jsonList[i] as Map<String, dynamic>;

          if (!validateQuestionStructure(questionJson)) {
            throw Exception('Invalid structure in question ${i + 1}');
          }

          Question question = Question.fromJson(questionJson);
          questions.add(question);
        } catch (e) {
          throw Exception('Error processing question ${i + 1}: $e');
        }
      }

      return questions;
    } catch (e) {
      if (e.toString().contains('Unable to load asset')) {
        throw Exception(
          'Unable to load asset: Question file "$fileName" not found in assets/questions/',
        );
      } else if (e is FormatException) {
        throw Exception(
          'FormatException: Invalid JSON format in question file',
        );
      } else if (e.toString().contains('type')) {
        throw Exception('TypeError: Invalid data structure in question file');
      } else {
        throw Exception('Failed to load questions: ${e.toString()}');
      }
    }
  }

  // Helper method to validate JSON structure
  static bool validateQuestionStructure(Map<String, dynamic> questionJson) {
    final requiredKeys = ['options', 'correctAnswer'];

    // Check required keys
    for (String key in requiredKeys) {
      if (!questionJson.containsKey(key)) {
        return false;
      }
    }

    // Validate data types
    if (questionJson.containsKey('id') && questionJson['id'] is! int) {
      return false;
    }

    if (questionJson.containsKey('question') &&
        questionJson['question'] is! String) {
      return false;
    }

    if (questionJson.containsKey('questionType') &&
        questionJson['questionType'] is! String) {
      return false;
    }

    if (questionJson['options'] is! List) {
      return false;
    }

    if (questionJson['correctAnswer'] is! int) {
      return false;
    }

    // Validate correctAnswer range
    int correctAnswer = questionJson['correctAnswer'];
    List options = questionJson['options'];
    if (correctAnswer < 0 || correctAnswer >= options.length) {
      return false;
    }

    // Validate question type specific requirements
    String? questionType = questionJson['questionType'] as String?;
    if (questionType != null) {
      switch (questionType) {
        case 'text':
          // Text questions must have non-empty question text
          String? question = questionJson['question'] as String?;
          if (question == null || question.isEmpty) {
            return false;
          }
          break;
        case 'text_with_image':
          // Text with image questions must have both question text and image path
          String? question = questionJson['question'] as String?;
          String? imagePath = questionJson['imagePath'] as String?;
          if ((question == null || question.isEmpty) ||
              (imagePath == null || imagePath.isEmpty)) {
            return false;
          }
          break;
        case 'image_only':
          // Image only questions must have image path
          String? imagePath = questionJson['imagePath'] as String?;
          if (imagePath == null || imagePath.isEmpty) {
            return false;
          }
          break;
      }
    }

    return true;
  }

  // Utility method to get question statistics
  static Map<String, dynamic> getQuestionStats(List<Question> questions) {
    int questionsWithExplanation = questions
        .where((q) => q.explanation != null && q.explanation!.isNotEmpty)
        .length;
    int questionsWithReference = questions
        .where((q) => q.reference != null && q.reference!.isNotEmpty)
        .length;
    int questionsWithImages = questions.where((q) => q.hasImage).length;

    Map<int, int> optionCounts = {};
    Map<String, int> questionTypeCounts = {};

    for (Question q in questions) {
      int optionCount = q.options.length;
      optionCounts[optionCount] = (optionCounts[optionCount] ?? 0) + 1;

      String type = q.questionType ?? 'unknown';
      questionTypeCounts[type] = (questionTypeCounts[type] ?? 0) + 1;
    }

    return {
      'totalQuestions': questions.length,
      'questionsWithExplanation': questionsWithExplanation,
      'questionsWithReference': questionsWithReference,
      'questionsWithImages': questionsWithImages,
      'optionDistribution': optionCounts,
      'questionTypeDistribution': questionTypeCounts,
    };
  }

  // Filter questions by type
  static List<Question> getQuestionsByType(
    List<Question> questions,
    String questionType,
  ) {
    return questions.where((q) => q.questionType == questionType).toList();
  }

  // Get questions with images
  static List<Question> getQuestionsWithImages(List<Question> questions) {
    return questions.where((q) => q.hasImage).toList();
  }

  // Get questions without images
  static List<Question> getQuestionsWithoutImages(List<Question> questions) {
    return questions.where((q) => !q.hasImage).toList();
  }

  // Utility method to shuffle all questions' options
  static void shuffleAllQuestions(List<Question> questions) {
    for (Question question in questions) {
      question.shuffleOptions();
    }
  }

  // Utility method to reset all questions' options
  static void resetAllQuestions(List<Question> questions) {
    for (Question question in questions) {
      question.resetOptions();
    }
  }

  // Utility method to get random subset of questions
  static List<Question> getRandomQuestions(
    List<Question> questions,
    int count,
  ) {
    if (count >= questions.length) {
      return List.from(questions);
    }

    List<Question> shuffled = List.from(questions);
    shuffled.shuffle(Random());
    return shuffled.take(count).toList();
  }

  // Get random questions by type
  static List<Question> getRandomQuestionsByType(
    List<Question> questions,
    String questionType,
    int count,
  ) {
    List<Question> filteredQuestions = getQuestionsByType(
      questions,
      questionType,
    );
    return getRandomQuestions(filteredQuestions, count);
  }

  // Validate image paths exist in assets
  static Future<List<String>> validateImagePaths(
    List<Question> questions,
  ) async {
    List<String> missingImages = [];

    for (Question question in questions) {
      if (question.hasImage) {
        try {
          await rootBundle.load(question.imagePath!);
        } catch (e) {
          missingImages.add(question.imagePath!);
        }
      }
    }

    return missingImages;
  }
}
