import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_session_model.dart';
import '../services/quiz_service.dart';
import '../services/quiz_connection_service.dart';
import '../widgets/participant_status_list.dart';
import './main_quiz_screen.dart';

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

  @override
  void dispose() {
    _isDisposed = true;
    // Fixed: Use leaveSession instead of disposeSession
    _quizService.leaveSession(widget.session.id, widget.currentUserId);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionStream = _quizService.getSessionUpdates(widget.session.id);
    _initializeConnection();
  }

  void _initializeConnection() {
    // Start heartbeat monitoring
    _connectionService.startHeartbeat(widget.session.id, widget.currentUserId);

    // Initialize regular connection status checks
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _connectionService.checkConnectionStatus(widget.session.id);
    });
  }

  Widget _buildWaitingRoom(QuizSessionModel session) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Waiting for players to join...',
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
    final bool canStart = session.canStartQuiz();

    return Column(
      children: [
        ElevatedButton(
          onPressed: canStart ? () => _quizService.startQuiz(session.id) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            canStart ? 'Start Quiz' : 'Need at least 2 online players',
            style: const TextStyle(fontSize: 18),
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

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz session cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );

        // Navigate back immediately
        Navigator.of(context).pop();
      }
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

    return const QuizScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuizSessionModel>(
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

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.session.quizName),
            backgroundColor: Colors.teal.shade600,
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
                  if (!_isDisposed && mounted) {
                    // Show cancellation message briefly before navigating back
                    Future.microtask(() {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quiz session has been cancelled'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    });
                  }
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
                  // TODO: Handle this case.
                  throw UnimplementedError();
              }
            },
          ),
        );
      },
    );
  }
}
