import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quiz_session_model.dart';
import '../services/quiz_service.dart';
import 'quiz_game_screen.dart'; // For MultilineOptionButton

class MultiplayerQuizGameScreen extends StatefulWidget {
  final QuizSessionModel session;
  final String currentUserId;

  const MultiplayerQuizGameScreen({
    super.key,
    required this.session,
    required this.currentUserId,
  });

  @override
  State<MultiplayerQuizGameScreen> createState() =>
      _MultiplayerQuizGameScreenState();
}

class _MultiplayerQuizGameScreenState extends State<MultiplayerQuizGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _buttonPressAnimation;

  Timer? _questionTimer;
  Timer? _autoNextTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription<QuizSessionModel>? _sessionSubscription;

  bool _isConnected = true;
  bool _isReconnecting = false;
  int remainingTime = 0;
  bool timeUp = false;
  bool showConfetti = false;
  int streakCount = 0;
  int pressedButtonIndex = -1;

  int? _lastQuestionIndex;
  int? _lastQuestionStartTime;
  bool _waitingForNext = false;
  bool _isLoading = false;
  bool _isUpdatingState = false;

  // Add session state tracking
  QuizSessionModel? _currentSession;
  bool _hasInitialData = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session; // Initialize with passed session
    remainingTime = widget.session.questionTimeLimit;
    _initializeConnectivityMonitoring();
    _initializeAnimations();
    _initializeSessionStream();
  }

  void _initializeSessionStream() {
    // Start listening to session updates immediately
    _sessionSubscription = QuizService()
        .getSessionUpdates(widget.session.id)
        .listen(
          (session) {
            if (mounted) {
              _handleSessionUpdate(session);
            }
          },
          onError: (error) {
            print('DEBUG: Session stream error: $error');
            if (mounted) {
              setState(() {
                _isConnected = false;
                _isReconnecting = true;
              });
            }
          },
        );
  }

  void _handleSessionUpdate(QuizSessionModel session) {
    print(
      'DEBUG: Received session update - status: ${session.status}, questionIndex: ${session.currentQuestionIndex}',
    );

    if (!mounted || _isUpdatingState) return;

    // Update current session
    setState(() {
      _currentSession = session;
      _hasInitialData = true;
    });

    // Handle session state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleSessionStateChange(session);
      }
    });
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: Duration(seconds: widget.session.questionTimeLimit),
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
    _shakeAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _buttonPressAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeOut),
    );
  }

  void _initializeConnectivityMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
    });

    // Initial connection status update
    QuizService().updateParticipantConnectionStatus(
      widget.session.id,
      widget.currentUserId,
      true,
    );
  }

  Future<void> _checkConnection() async {
    try {
      await QuizService().pingSession(widget.session.id);
      if (!_isConnected && mounted && !_isUpdatingState) {
        _safeSetState(() {
          _isConnected = true;
          _isReconnecting = false;
        });
        print('DEBUG: Connection restored');
      }
    } catch (e) {
      if (_isConnected && mounted && !_isUpdatingState) {
        _safeSetState(() {
          _isConnected = false;
          _isReconnecting = true;
        });
        print('DEBUG: Connection lost - Error: $e');
        _handleDisconnection();
      }
    }
  }

  // Safe setState wrapper to prevent conflicts
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isUpdatingState) {
      _isUpdatingState = true;
      setState(fn);
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _isUpdatingState = false;
        }
      });
    }
  }

  void _handleDisconnection() async {
    if (!mounted) return;

    // Update connection status in Firebase
    await QuizService().updateParticipantConnectionStatus(
      widget.session.id,
      widget.currentUserId,
      false,
    );

    // Attempt to reconnect
    _attemptReconnection();
  }

  void _attemptReconnection() async {
    if (!mounted) return;

    while (!_isConnected && mounted) {
      try {
        await QuizService().pingSession(widget.session.id);
        if (mounted && !_isUpdatingState) {
          _safeSetState(() {
            _isConnected = true;
            _isReconnecting = false;
          });
          print('DEBUG: Reconnection successful');

          // Sync with current question state
          if (_currentSession != null) {
            _syncWithCurrentQuestion(_currentSession!);
          }
        }
        break;
      } catch (e) {
        print('DEBUG: Reconnection attempt failed: $e');
        await Future.delayed(const Duration(seconds: 3));
      }
    }
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
    _connectionCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _sessionSubscription?.cancel();
    _audioPlayer.dispose();

    // Update connection status on dispose
    QuizService().updateParticipantConnectionStatus(
      widget.session.id,
      widget.currentUserId,
      false,
    );

    super.dispose();
  }

  Future<void> _playWrongSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      debugPrint('Failed to play wrong sound: $e');
    }
  }

  void _syncWithCurrentQuestion(QuizSessionModel session) {
    if (!mounted || _isUpdatingState) return;

    _safeSetState(() {
      _isLoading = true;
    });

    // Use post frame callback to ensure safe execution
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        if (session.currentQuestionIndex != _lastQuestionIndex) {
          _lastQuestionIndex = session.currentQuestionIndex;
          _lastQuestionStartTime = DateTime.now().millisecondsSinceEpoch;
          _startTimer(
            session.questionTimeLimit,
            startTimeMillis: _lastQuestionStartTime,
          );
        }
      } finally {
        if (mounted && !_isUpdatingState) {
          _safeSetState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  void _handleTimeUp() async {
    if (mounted && !_isUpdatingState) {
      _safeSetState(() {
        timeUp = true;
      });
    }
    HapticFeedback.heavyImpact();
    await _playWrongSound();

    // If host, wait a short delay then move to next question
    if (widget.session.hostId == widget.currentUserId) {
      _safeSetState(() {
        _isLoading = true;
      });
      try {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          await QuizService().moveToNextQuestion(widget.session.id);
        }
      } catch (e) {
        print('DEBUG: Failed to move to next question: $e');
      } finally {
        if (mounted && !_isUpdatingState) {
          _safeSetState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _selectAnswer(
    int answerIndex,
    String sessionId,
    int questionIndex,
  ) async {
    if (!_isConnected) {
      print('DEBUG: Cannot submit answer while offline');
      return;
    }

    if (timeUp) {
      // Optionally show a snackbar or shake animation for late answer
      _shakeController.forward(from: 0.0);
      await _playWrongSound();
      HapticFeedback.heavyImpact();
      return;
    }

    _safeSetState(() {
      pressedButtonIndex = answerIndex;
      _isLoading = true;
    });

    try {
      _buttonPressController.forward().then((_) {
        _buttonPressController.reverse();
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _questionTimer?.cancel();
      _pulseController.stop();

      await QuizService().submitParticipantAnswer(
        sessionId: sessionId,
        userId: widget.currentUserId,
        answer: answerIndex,
      );
    } catch (e) {
      print('DEBUG: Failed to submit answer - Error: $e');
    } finally {
      if (mounted && !_isUpdatingState) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }

    // Immediate feedback: play sound and haptic
    if (_currentSession != null) {
      final questions = _currentSession!.questions;
      if (questionIndex < questions.length) {
        final correctAnswer = questions[questionIndex]['correctAnswer'];
        if (answerIndex == correctAnswer) {
          // Correct
          await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
          HapticFeedback.mediumImpact();
        } else {
          // Incorrect
          await _playWrongSound();
          HapticFeedback.heavyImpact();
          _shakeController.forward(from: 0.0);
        }
      }
    }

    _safeSetState(() {
      pressedButtonIndex = -1;
    });
  }

  Color _getTimerColor() {
    if (remainingTime <= 5) return const Color(0xFFE74C3C);
    if (remainingTime <= 10) return const Color(0xFFFF9500);
    return const Color(0xFF58CC02);
  }

  Widget _buildQuizStatusDisplay(
    QuizStatus status,
    QuizSessionModel session,
    bool isHost,
    bool isTablet,
  ) {
    if (status == QuizStatus.completed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quiz Finished!',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4B4B4B),
            ),
          ),
          const SizedBox(height: 20),
          _buildLeaderboard(session),
        ],
      );
    }

    // Check for disconnected players
    final disconnectedPlayers = session.participants.values
        .where((p) => p.connectionStatus == ConnectionStatus.reconnecting)
        .toList();

    if (disconnectedPlayers.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Waiting for reconnection...',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B4B4B),
            ),
          ),
          const SizedBox(height: 12),
          ...disconnectedPlayers.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '${p.userName} reconnecting...',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Regular waiting state
    return Text(
      'Waiting for other players...${isHost && status == QuizStatus.waiting ? '\nTap start to begin.' : ''}',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isTablet ? 22 : 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF4B4B4B),
      ),
    );
  }

  Widget _buildLeaderboard(QuizSessionModel session) {
    final sortedParticipants = session.participants.values.toList()
      ..sort((a, b) => (b.score).compareTo(a.score));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedParticipants.length,
      itemBuilder: (context, index) {
        final participant = sortedParticipants[index];
        final isCurrentUser = participant.userId == widget.currentUserId;
        final medal = index < 3 ? ['🥇', '🥈', '🥉'][index] : '';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0xFF58CC02).withValues(alpha: 26)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF58CC02)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Text(
                medal.isEmpty ? '${index + 1}.' : medal,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  participant.userName,
                  style: TextStyle(
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '${participant.score} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58CC02),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionsDisplay(
    Map<String, dynamic> currentQuestion,
    bool isSmallScreen,
    bool isTablet,
    int correctAnswer,
    int? selectedAnswer,
    bool isAnswered,
    bool timeUp,
    BuildContext context,
  ) {
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: (currentQuestion['options'] as List).length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isSmallScreen ? 12 : 16),
      itemBuilder: (context, index) {
        bool isCorrect = index == correctAnswer;
        bool isSelected = index == selectedAnswer;
        bool isPressed = index == pressedButtonIndex;
        return MultilineOptionButton(
          option: (currentQuestion['options'] as List)[index],
          optionLabel: String.fromCharCode(65 + index),
          isSelected: isSelected,
          isCorrect: isCorrect,
          isAnswered: isAnswered,
          timeUp: timeUp,
          isPressed: isPressed,
          onTap: () => _selectAnswer(
            index,
            widget.session.id,
            _currentSession?.currentQuestionIndex ?? 0,
          ),
          shakeAnimation: _shakeAnimation,
          buttonPressAnimation: _buttonPressAnimation,
          isSmallScreen: isSmallScreen,
          isTablet: isTablet,
        );
      },
    );
  }

  void _handleSessionStateChange(QuizSessionModel session) {
    if (_isUpdatingState) return;

    bool questionChanged = _lastQuestionIndex != session.currentQuestionIndex;
    bool startTimeChanged = false;

    int? newStartTime =
        session.currentQuestionStartTime?.millisecondsSinceEpoch;
    if (_lastQuestionStartTime != newStartTime) {
      startTimeChanged = true;
    }

    if (questionChanged || startTimeChanged) {
      print(
        'DEBUG: Question transition - questionChanged: $questionChanged, startTimeChanged: $startTimeChanged',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isUpdatingState) return;

        _fadeController.reset();
        _fadeController.forward();
        _pulseController.stop();
        _questionTimer?.cancel();
        _autoNextTimer?.cancel();
        _waitingForNext = false;

        if (session.status == QuizStatus.active &&
            session.hasQuestionsLoaded() &&
            session.currentQuestionIndex < session.questions.length) {
          print(
            'DEBUG: Starting timer for question ${session.currentQuestionIndex}',
          );

          if (session.currentQuestionStartTime != null) {
            _startTimer(
              session.questionTimeLimit,
              startTimeMillis:
                  session.currentQuestionStartTime!.millisecondsSinceEpoch,
            );
          } else {
            print('DEBUG: No start time yet, setting initial state');
            _safeSetState(() {
              remainingTime = session.questionTimeLimit;
              timeUp = false;
            });
          }
        } else {
          print('DEBUG: Session not active or invalid state, resetting timer');
          _safeSetState(() {
            remainingTime = session.questionTimeLimit;
            timeUp = false;
          });
          _timerController.reset();
        }

        _lastQuestionIndex = session.currentQuestionIndex;
        _lastQuestionStartTime = newStartTime;
      });
    }

    _handleAutoProgression(session);
  }

  void _handleAutoProgression(QuizSessionModel session) {
    final isHost = session.hostId == widget.currentUserId;

    if (!isHost || session.status != QuizStatus.active || _waitingForNext) {
      return;
    }

    final answersMap = session.participantAnswers;
    final onlineParticipants = session.participants.values
        .where((p) => p.connectionStatus == ConnectionStatus.online)
        .toList();
    final totalOnlinePlayers = onlineParticipants.length;
    final currentQuestionIndex = session.currentQuestionIndex;

    int answeredCount = 0;
    for (final participant in onlineParticipants) {
      final userAnswers = answersMap[participant.userId];
      if (userAnswers != null && userAnswers.length > currentQuestionIndex) {
        final answer = userAnswers[currentQuestionIndex];
        if (answer != -1) {
          answeredCount++;
        }
      }
    }

    final allOnlineAnswered = answeredCount >= totalOnlinePlayers;

    if (allOnlineAnswered && session.currentQuestionStartTime != null) {
      final questionRunTime = DateTime.now().difference(
        session.currentQuestionStartTime!,
      );
      final minQuestionTime = const Duration(seconds: 3);

      if (questionRunTime >= minQuestionTime) {
        print(
          'DEBUG: All online players ($answeredCount/$totalOnlinePlayers) answered, auto-progressing...',
        );
        _waitingForNext = true;
        _autoNextTimer?.cancel();

        _autoNextTimer = Timer(const Duration(milliseconds: 1500), () async {
          if (!mounted) return;
          try {
            await QuizService().moveToNextQuestion(session.id);
          } catch (e) {
            print('DEBUG: Auto-progression failed: $e');
            if (mounted) {
              _safeSetState(() {
                _waitingForNext = false;
              });
            }
          }
        });
      }
    }
  }

  void _startTimer(int duration, {int? startTimeMillis}) {
    print(
      'DEBUG: Starting timer - duration: ${duration}s, startTime: $startTimeMillis',
    );

    _questionTimer?.cancel();
    _timerController.reset();

    int elapsed = 0;
    int timeLeft = duration;

    if (startTimeMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      elapsed = ((now - startTimeMillis) / 1000).floor();
      if (elapsed < 0) elapsed = 0;
      timeLeft = duration - elapsed;
      if (timeLeft < 0) timeLeft = 0;
    }

    _timerController.duration = Duration(seconds: duration);

    if (timeLeft > 0 && elapsed >= 0) {
      final progress = elapsed.toDouble() / duration.toDouble();
      _timerController.forward(from: progress.clamp(0.0, 1.0));
    } else if (timeLeft <= 0) {
      _timerController.value = 1.0;
    }

    _safeSetState(() {
      remainingTime = timeLeft;
      timeUp = timeLeft <= 0;
    });

    if (timeLeft > 0) {
      _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        _safeSetState(() {
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
    } else if (timeLeft <= 0) {
      _handleTimeUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isTablet = screenSize.width > 600;

    // Use the current session from our state management
    if (!_hasInitialData || _currentSession == null) {
      return _buildLoadingScreen(context, 'Loading quiz session...');
    }

    final session = _currentSession!;
    print(
      'DEBUG: Building with session - status: ${session.status}, questionIndex: ${session.currentQuestionIndex}',
    );

    // Check for basic session validity
    if (!session.participants.containsKey(widget.currentUserId)) {
      return _buildInvalidSessionScreen(context, session);
    }

    // Handle different session states
    switch (session.status) {
      case QuizStatus.completed:
        return _buildCompletedScreen(context, session, isTablet);

      case QuizStatus.cancelled:
      case QuizStatus.expired:
        return _buildCancelledScreen(context, session);

      case QuizStatus.waiting:
        return _buildWaitingScreen(context, session, isTablet);

      case QuizStatus.active:
        if (session.questions.isEmpty) {
          return _buildLoadingScreen(context, 'Loading quiz questions...');
        }

        if (session.currentQuestionIndex >= session.questions.length) {
          print('DEBUG: Invalid question index during transition, waiting...');
          return _buildLoadingScreen(context, 'Preparing next question...');
        }

        return _buildGameScreen(context, session, isSmallScreen, isTablet);

      default:
        return _buildLoadingScreen(context, 'Preparing quiz...');
    }
  }

  // ... (Keep all the existing _build methods unchanged)
  Widget _buildLoadingScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidSessionScreen(
    BuildContext context,
    QuizSessionModel session,
  ) {
    String message = 'Quiz session error';

    if (session.status == QuizStatus.active && !session.hasQuestionsLoaded()) {
      message = 'Quiz questions not loaded';
    } else if (session.currentQuestionIndex >= session.questions.length) {
      message = 'Invalid question data';
    } else if (!session.participants.containsKey(widget.currentUserId)) {
      message = 'You are no longer part of this quiz';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (session.status == QuizStatus.active &&
                session.currentQuestionIndex >= session.questions.length)
              Text(
                'Question ${session.currentQuestionIndex + 1}/${session.questions.length}',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingScreen(
    BuildContext context,
    QuizSessionModel session,
    bool isTablet,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            _buildQuizStatusDisplay(
              session.status,
              session,
              session.hostId == widget.currentUserId,
              isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(
    BuildContext context,
    QuizSessionModel session,
    bool isTablet,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Quiz Complete!'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Quiz Finished!',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4B4B4B),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(child: _buildLeaderboard(session)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledScreen(BuildContext context, QuizSessionModel session) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Multiplayer Quiz'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF4B4B4B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _getStatusMessage(session.status),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(
    BuildContext context,
    QuizSessionModel session,
    bool isSmallScreen,
    bool isTablet,
  ) {
    final questions = session.questions;
    final currentQuestionIndex = session.currentQuestionIndex;
    final currentQuestion = questions[currentQuestionIndex];
    final userAnswers = session.participantAnswers[widget.currentUserId] ?? [];
    final selectedAnswer = (userAnswers.length > currentQuestionIndex)
        ? userAnswers[currentQuestionIndex]
        : null;
    final isAnswered = selectedAnswer != null && selectedAnswer != -1;
    final correctAnswer = currentQuestion['correctAnswer'];
    final participantCount = session.participants.length;
    final userScore = session.participants[widget.currentUserId]?.score ?? 0;

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
              title: Row(
                children: [
                  Text(
                    '${session.subject.isNotEmpty ? session.subject : session.quizName} Quiz',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B4B4B),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CB0F6).withValues(alpha: 26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.group,
                          color: Color(0xFF1CB0F6),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('$participantCount'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF58CC02).withValues(alpha: 31),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFF58CC02),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$userScore',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Timer progress bar
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
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question card
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
                      if (currentQuestion['reference'] != null)
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
                                  ).withValues(alpha: 77),
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
                                    currentQuestion['reference']!,
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
                      if ((currentQuestion['question'] ?? '').isNotEmpty)
                        Text(
                          currentQuestion['question'],
                          style: TextStyle(
                            fontSize: isTablet ? 20 : (isSmallScreen ? 16 : 18),
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: const Color(0xFF4B4B4B),
                          ),
                        ),
                      if (currentQuestion['imagePath'] != null) ...[
                        SizedBox(
                          height: (currentQuestion['question'] ?? '').isNotEmpty
                              ? 16
                              : 0,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            currentQuestion['imagePath'],
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
                // Options display
                Expanded(
                  child: _buildOptionsDisplay(
                    currentQuestion,
                    isSmallScreen,
                    isTablet,
                    correctAnswer,
                    selectedAnswer,
                    isAnswered,
                    timeUp,
                    context,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(QuizStatus status) {
    switch (status) {
      case QuizStatus.waiting:
        return 'Waiting for quiz to start...';
      case QuizStatus.completed:
        return 'Quiz Complete!';
      case QuizStatus.cancelled:
        return 'Quiz Cancelled';
      case QuizStatus.expired:
        return 'Quiz Expired';
      default:
        return 'Quiz Loading...';
    }
  }
}
