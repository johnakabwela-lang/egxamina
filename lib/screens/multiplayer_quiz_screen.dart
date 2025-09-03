import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_session_model.dart';
import '../services/quiz_service.dart';
import '../services/quiz_connection_service.dart';
import '../widgets/participant_status_list.dart';
import 'multiplayer_quiz_game_screen.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final QuizSessionModel session;
  final String currentUserId;

  const MultiplayerQuizScreen({
    super.key,
    required this.session,
    required this.currentUserId,
  });

  @override
  MultiplayerQuizScreenState createState() => MultiplayerQuizScreenState();
}

class MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  late Stream<QuizSessionModel> _sessionStream;
  final QuizService _quizService = QuizService();
  final QuizConnectionService _connectionService = QuizConnectionService();
  bool _isDisposed = false;
  bool _isCancelling = false;
  bool _isLeaving = false;
  Timer? _connectionTimer;
  Timer? _countdownTimer;
  static const int waitingRoomDuration = 120; // 2 minutes
  int _remainingSeconds = waitingRoomDuration;
  int _onlineUsersCount = 1; // Start with 1 (host)

  @override
  void dispose() {
    _isDisposed = true;
    _connectionTimer?.cancel();
    _countdownTimer?.cancel();
    if (!_isLeaving) {
      // Handle ungraceful disconnect (when user force-closes app or navigates without proper leaving)
      _connectionService.stopTracking(widget.session.id);
    }
    super.dispose();
  }

  // Initialize countdown timer
  void _initializeCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _handleCountdownExpiry();
        }
      });
    });
  }

  // Handle countdown expiry
  void _handleCountdownExpiry() {
    _countdownTimer?.cancel();
    if (_isDisposed || !mounted) return;

    // Auto-cancel the quiz session
    if (_isHost(widget.session)) {
      _cancelQuizSession(widget.session);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz waiting period has expired'),
        backgroundColor: Colors.orange,
      ),
    );

    // Navigate back
    Navigator.of(context).pop();
  }

  // Format remaining time as MM:SS
  String _formatRemainingTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get color for countdown display
  Color _getCountdownColor() {
    if (_remainingSeconds <= 10) return Colors.red;
    if (_remainingSeconds <= 30) return Colors.orange;
    return Colors.black87;
  }

  // Update user count and start button state
  void _updateOnlineUsersCount(QuizSessionModel session) {
    if (!mounted) return;

    final onlineCount = session.participants.values
        .where((p) => p.connectionStatus == ConnectionStatus.online)
        .length;

    // Only update if the count has actually changed
    if (onlineCount != _onlineUsersCount) {
      setState(() {
        _onlineUsersCount = onlineCount;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionStream = _quizService.getSessionUpdates(widget.session.id);
    _initializeConnection();
    _initializeCountdown();
  }

  void _initializeConnection() {
    // Start comprehensive tracking (heartbeat + presence)
    _connectionService.startTracking(widget.session.id);

    // Initialize regular connection status checks
    _connectionTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _connectionService.checkConnectionStatus(widget.session.id);
    });
  }

  // Handle proper leave session
  Future<void> _leaveSession() async {
    if (_isLeaving) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      await _connectionService.leaveSession(
        widget.session.id,
        widget.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left quiz session'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Override back button behavior
  Future<bool> _onWillPop() async {
    if (_isLeaving || _isCancelling) return false;

    // Show confirmation dialog for leaving
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Quiz Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to leave this quiz session?'),
              const SizedBox(height: 12),
              if (_isHost(widget.session))
                const Text(
                  'As the host, leaving will either transfer hosting to another player or cancel the session if no other players are online.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                )
              else
                const Text(
                  'You can rejoin later if the quiz is still active.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Leave', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      await _leaveSession();
    }

    return false; // Always prevent default back navigation
  }

  Widget _buildWaitingRoom(QuizSessionModel session) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Waiting for players to join... ($_onlineUsersCount online)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(child: ParticipantStatusList(session: session)),
        const SizedBox(height: 20),
        if (_isHost(session)) _buildHostControls(session),
      ],
    );
  }

  Widget _buildHostControls(QuizSessionModel session) {
    final bool canStart = _onlineUsersCount >= 2;

    return Column(
      children: [
        ElevatedButton(
          onPressed: canStart
              ? () => _quizService.startQuizSession(session.id)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            canStart ? 'Start Quiz' : 'Need at least 2 online players',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        // Cancel Quiz Session Button
        ElevatedButton(
          onPressed: _isCancelling
              ? null
              : () => _showCancelConfirmationDialog(session),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: _isCancelling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Cancel Quiz',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _showCancelConfirmationDialog(QuizSessionModel session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Quiz Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to cancel this quiz session?'),
              const SizedBox(height: 8),
              Text(
                'Quiz: ${session.quizName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Participants: ${session.participants.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone and all participants will be notified.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Session'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelQuizSession(session);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Cancel Quiz',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelQuizSession(QuizSessionModel session) async {
    if (!mounted) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _quizService.cancelSession(session.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz session cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );

      // Navigate back immediately
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isHost(QuizSessionModel session) {
    return session.hostId == widget.currentUserId;
  }

  Widget _buildQuizInProgress(QuizSessionModel session) {
    if (session.shouldPauseQuiz) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Quiz Paused',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting for players to reconnect...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(child: ParticipantStatusList(session: session)),
            // Add cancel option even during paused state for host
            if (_isHost(session)) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isCancelling
                    ? null
                    : () => _showCancelConfirmationDialog(session),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cancel Quiz',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      );
    }

    return MultiplayerQuizGameScreen(
      session: session,
      currentUserId: widget.currentUserId,
    );
  }

  void _handleSessionCancelled() {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz session has been cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: StreamBuilder<QuizSessionModel>(
        stream: _sessionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          final session = snapshot.data!;

          // Update online users count immediately
          _updateOnlineUsersCount(session);

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.session.quizName),
              backgroundColor: Colors.teal.shade600,
              leading: _isLeaving || _isCancelling
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _onWillPop(),
                    ),
              actions: [
                // Show reconnection status if applicable
                if (session.reconnectingParticipants.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${session.reconnectingParticipants.length} reconnecting...',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
              ],
            ),
            body: Builder(
              builder: (context) {
                switch (session.status) {
                  case QuizStatus.waiting:
                    return _buildWaitingRoom(session);
                  case QuizStatus.active:
                    return _buildQuizInProgress(session);
                  case QuizStatus.completed:
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ParticipantStatusList(
                        session: session,
                        showStatusDot: false,
                      ),
                    );
                  case QuizStatus.cancelled:
                    // Use a post-frame callback to handle navigation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleSessionCancelled();
                    });
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 64,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Quiz has been cancelled',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  case QuizStatus.expired:
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Quiz session has expired',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The waiting room timed out',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
