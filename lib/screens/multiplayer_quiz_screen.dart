import 'package:flutter/material.dart';
import '../models/quiz_session_model.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../services/quiz_presence_service.dart';
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
  _MultiplayerQuizScreenState createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  late Stream<QuizSessionModel> _sessionStream;
  late Stream<Map<String, bool>> _presenceStream;
  final QuizService _quizService = QuizService();
  final AuthService _authService = AuthService();
  final QuizPresenceService _presenceService = QuizPresenceService();
  Map<String, bool> _presence = {};

  @override
  void dispose() {
    _presenceService.stopTracking(widget.session.id);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionStream = _quizService.getSessionUpdates(widget.session.id);
    _presenceStream = _presenceService.getPresenceUpdates(widget.session.id);
    _presenceService.startTracking(widget.session.id);
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
        _buildParticipantsList(session),
        const SizedBox(height: 20),
        if (_isHost(session)) _buildHostControls(session),
      ],
    );
  }

  Widget _buildParticipantsList(QuizSessionModel session) {
    return StreamBuilder<Map<String, bool>>(
      stream: _presenceStream,
      builder: (context, presenceSnapshot) {
        _presence = presenceSnapshot.data ?? {};

        return ListView.builder(
          shrinkWrap: true,
          itemCount: session.participants.length,
          itemBuilder: (context, index) {
            final participant = session.sortedParticipantsByScore[index];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    child: Text(participant.userName[0].toUpperCase()),
                  ),
                  if (_presence[participant.userId] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(participant.userName),
              trailing: session.isCompleted
                  ? Text(
                      '${participant.score} points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  : _buildParticipantStatus(participant),
            );
          },
        );
      },
    );
  }

  Widget _buildParticipantStatus(QuizParticipant participant) {
    if (!participant.hasJoined) {
      return const Text(
        'Not Joined',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    if (_presence[participant.userId] == true) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Online',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 4),
          Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      );
    }

    return const Text(
      'Offline',
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildHostControls(QuizSessionModel session) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: session.joinedParticipantCount > 1
              ? () => _quizService.startQuiz(session.id)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Start Quiz', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _quizService.cancelSession(session.id),
          child: const Text('Cancel Session'),
        ),
      ],
    );
  }

  bool _isHost(QuizSessionModel session) {
    return session.participants[widget.currentUserId]?.userId ==
        widget.currentUserId;
  }

  Widget _buildLeaderboard(QuizSessionModel session) {
    final sortedParticipants = session.sortedParticipantsByScore;

    return Column(
      children: [
        const Text(
          'Final Results',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          itemCount: sortedParticipants.length,
          itemBuilder: (context, index) {
            final participant = sortedParticipants[index];
            final isWinner = index == 0;

            return Card(
              elevation: isWinner ? 5 : 1,
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isWinner ? Colors.yellow : Colors.grey[300],
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  participant.userName,
                  style: TextStyle(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  '${participant.score} points',
                  style: TextStyle(
                    color: isWinner ? Colors.green : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.quizName),
        backgroundColor: Colors.teal.shade600,
      ),
      body: StreamBuilder<QuizSessionModel>(
        stream: _sessionStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = snapshot.data!;

          if (session.isCancelled) {
            return const Center(child: Text('Quiz session was cancelled'));
          }

          if (session.isCompleted) {
            return _buildLeaderboard(session);
          }

          if (session.isWaiting) {
            return _buildWaitingRoom(session);
          }

          // Active quiz session
          return const QuizScreen();
        },
      ),
    );
  }
}
