import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:ultsukulu/managers/streak_manager.dart';

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
}

// Independent Options Card Widget
class PressEffectedWidget extends StatefulWidget {
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
  });

  @override
  State<PressEffectedWidget> createState() => _PressEffectedWidgetState();
}

class _PressEffectedWidgetState extends State<PressEffectedWidget> {
  @override
  Widget build(BuildContext context) {
    Color cardColor = Colors.white;
    Color borderColor = const Color(0xFFE5E5E5);
    Color shadowColor = Colors.black12;
    IconData? icon;
    Color iconColor = Colors.transparent;
    double elevation = 8;

    if (widget.isAnswered || widget.timeUp) {
      if (widget.isSelected && widget.isCorrect) {
        cardColor = const Color(0xFF58CC02).withOpacity(0.1);
        borderColor = const Color(0xFF58CC02);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF58CC02);
        shadowColor = const Color(0xFF58CC02).withOpacity(0.3);
      } else if (widget.isSelected && !widget.isCorrect) {
        cardColor = const Color(0xFFE74C3C).withOpacity(0.1);
        borderColor = const Color(0xFFE74C3C);
        icon = Icons.cancel;
        iconColor = const Color(0xFFE74C3C);
        shadowColor = const Color(0xFFE74C3C).withOpacity(0.3);
      } else if (widget.isCorrect) {
        cardColor = const Color(0xFF58CC02).withOpacity(0.1);
        borderColor = const Color(0xFF58CC02);
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF58CC02);
        shadowColor = const Color(0xFF58CC02).withOpacity(0.3);
      }

      if (widget.timeUp && !widget.isSelected && widget.isCorrect) {
        cardColor = const Color(0xFF58CC02).withOpacity(0.1);
        borderColor = const Color(0xFF58CC02);
        icon = Icons.check_circle;
        iconColor = const Color(0xFF58CC02);
        shadowColor = const Color(0xFF58CC02).withOpacity(0.3);
      }
    } else if (widget.isSelected) {
      cardColor = const Color(0xFF1CB0F6).withOpacity(0.1);
      borderColor = const Color(0xFF1CB0F6);
      shadowColor = const Color(0xFF1CB0F6).withOpacity(0.3);
    }

    // Button press effect
    if (widget.isPressed) {
      elevation = 2;
    }

    return AnimatedBuilder(
      animation: widget.shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (widget.isAnswered && widget.isSelected && !widget.isCorrect)
                ? widget.shakeAnimation.value
                : 0,
            0,
          ),
          child: AnimatedBuilder(
            animation: widget.buttonPressAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  widget.isPressed ? widget.buttonPressAnimation.value : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 0,
                          offset: Offset(0, elevation),
                        ),
                        if (!widget.isPressed)
                          BoxShadow(
                            color: borderColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      widget.isSelected ||
                                          (widget.isAnswered &&
                                              widget.isCorrect)
                                      ? (widget.isCorrect
                                            ? const Color(0xFF58CC02)
                                            : const Color(0xFFE74C3C))
                                      : const Color(0xFFF7F7F7),
                                  border: Border.all(
                                    color:
                                        widget.isSelected ||
                                            (widget.isAnswered &&
                                                widget.isCorrect)
                                        ? (widget.isCorrect
                                              ? const Color(0xFF58CC02)
                                              : const Color(0xFFE74C3C))
                                        : const Color(0xFFE5E5E5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (widget.isSelected ||
                                              (widget.isAnswered &&
                                                  widget.isCorrect))
                                          ? (widget.isCorrect
                                                    ? const Color(0xFF58CC02)
                                                    : const Color(0xFFE74C3C))
                                                .withOpacity(0.3)
                                          : Colors.black12,
                                      blurRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.optionLabel,
                                    style: TextStyle(
                                      color:
                                          widget.isSelected ||
                                              (widget.isAnswered &&
                                                  widget.isCorrect)
                                          ? Colors.white
                                          : const Color(0xFF777777),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.option,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    color: Color(0xFF4B4B4B),
                                  ),
                                ),
                              ),
                              if ((widget.isAnswered || widget.timeUp) &&
                                  icon != null)
                                AnimatedScale(
                                  scale: 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(icon, color: iconColor, size: 32),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
    super.dispose();
  }

  // Enhanced Sound effect methods with delay for wrong answer

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

      _autoNextTimer = Timer(const Duration(seconds: 4), () {
        _nextQuestion();
      });
    }
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
        if (streakCount >= 3) {}
        HapticFeedback.mediumImpact();
        _pulseController.forward().then((_) => _pulseController.reset());
      } else {
        // Wrong answer sound will play with 0.7s delay

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
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: Text(
            '${widget.subject} Quiz',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B4B4B),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.1),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loadQuestions,
                        icon: const Icon(Icons.refresh),
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
                      const SizedBox(width: 16),
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
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: const Color(0xFF4B4B4B),
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Streak
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: streakCount >= 3 
                          ? const Color(0xFFFF9500).withOpacity(0.1)
                          : const Color(0xFF777777).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: streakCount >= 3 
                            ? const Color(0xFFFF9500).withOpacity(0.3)
                            : const Color(0xFF777777).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: streakCount >= 3 
                              ? const Color(0xFFFF9500)
                              : const Color(0xFF777777),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streakCount',
                          style: TextStyle(
                            fontSize: 14,
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
                        scale: remainingTime <= 10 ? _pulseAnimation.value : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeUp ? 'Time Up!' : _formatTime(remainingTime),
                                style: TextStyle(
                                  fontSize: 14,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF58CC02).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '$score/${currentQuestionIndex + (isAnswered ? 1 : 0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF58CC02),
                      ),
                    ),
                  ),
                ],
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
                      widthFactor: timeUp ? 0.0 : (1.0 - _timerController.value),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: _getTimerColor(),
                      ),
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
        child: Column(
          children: [
            // Question content with Duolingo styling
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enhanced question card with Duolingo styling
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Question reference with Duolingo styling
                                if (questions[currentQuestionIndex].reference !=
                                    null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF8E44AD,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
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
                                          size: 14,
                                          color: Color(0xFF8E44AD),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          questions[currentQuestionIndex]
                                              .reference!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8E44AD),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Question number with Duolingo styling
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF58CC02,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF58CC02,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Question ${currentQuestionIndex + 1} of ${questions.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF58CC02),
                                    ),
                                  ),
                                ),

                                if (isAnswered || timeUp)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF58CC02,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF58CC02,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF58CC02),
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Next in 4s',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF58CC02),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              questions[currentQuestionIndex].question,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                                color: Color(0xFF4B4B4B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Enhanced options with PressEffectedWidget widget
                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              questions[currentQuestionIndex].options.length,
                          itemBuilder: (context, index) {
                            bool isCorrect =
                                index ==
                                questions[currentQuestionIndex].correctAnswer;
                            bool isSelected = index == selectedAnswer;
                            bool isPressed = index == pressedButtonIndex;

                            return PressEffectedWidget(
                              option: questions[currentQuestionIndex]
                                  .options[index],
                              optionLabel: String.fromCharCode(65 + index),
                              isSelected: isSelected,
                              isCorrect: isCorrect,
                              isAnswered: isAnswered,
                              timeUp: timeUp,
                              isPressed: isPressed,
                              onTap: () => _selectAnswer(index),
                              shakeAnimation: _shakeAnimation,
                              buttonPressAnimation: _buttonPressAnimation,
                            );
                          },
                        ),
                      ),

                      // Enhanced time up message with Duolingo styling
                      if (timeUp && selectedAnswer == -1)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE74C3C),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE74C3C).withOpacity(0.3),
                                blurRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.timer_off,
                                color: Color(0xFFE74C3C),
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time\'s Up! ⏰',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE74C3C),
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'You ran out of time for this question',
                                      style: TextStyle(
                                        color: Color(0xFF777777),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
class Question {
  final String question;
  final List<String> options;
  int correctAnswer;
  final String? explanation;
  final String? reference;

  // Store original options and correct answer for shuffling
  late List<String> _originalOptions;
  late int _originalCorrectAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.reference,
  }) {
    _originalOptions = List.from(options);
    _originalCorrectAnswer = correctAnswer;
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'reference': reference,
    };
  }

  void shuffleOptions() {
    List<MapEntry<int, String>> indexedOptions = [];
    for (int i = 0; i < options.length; i++) {
      indexedOptions.add(MapEntry(i, options[i]));
    }

    indexedOptions.shuffle(Random());

    for (int i = 0; i < indexedOptions.length; i++) {
      options[i] = indexedOptions[i].value;
      if (indexedOptions[i].key == _originalCorrectAnswer) {
        correctAnswer = i;
      }
    }
  }

  void resetOptions() {
    options.clear();
    options.addAll(_originalOptions);
    correctAnswer = _originalCorrectAnswer;
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
    final requiredKeys = ['question', 'options', 'correctAnswer'];

    // Check required keys
    for (String key in requiredKeys) {
      if (!questionJson.containsKey(key)) {
        return false;
      }
    }

    // Validate data types
    if (questionJson['question'] is! String) {
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

    Map<int, int> optionCounts = {};
    for (Question q in questions) {
      int optionCount = q.options.length;
      optionCounts[optionCount] = (optionCounts[optionCount] ?? 0) + 1;
    }

    return {
      'totalQuestions': questions.length,
      'questionsWithExplanation': questionsWithExplanation,
      'questionsWithReference': questionsWithReference,
      'optionDistribution': optionCounts,
    };
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
}
