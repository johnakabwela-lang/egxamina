import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/quiz_session_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionsCollection =
      'quizSessions'; // Changed from 'quiz_sessions'

  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // Start a new multiplayer quiz session
  Future<QuizSessionModel> startMultiplayerSession({
    required String groupId,
    required String quizName,
    required String hostUserId,
    required String hostUserName,
  }) async {
    final sessionRef = _firestore.collection(_sessionsCollection).doc();

    final session = QuizSessionModel(
      id: sessionRef.id,
      groupId: groupId,
      status: QuizStatus.waiting,
      participants: {
        hostUserId: QuizParticipant(
          userId: hostUserId,
          userName: hostUserName,
          hasJoined: true,
          joinedAt: DateTime.now(),
        ),
      },
      startedAt: null,
      quizName: quizName,
      hostUserId: hostUserId,
      hostId: '', // Make sure this field is included
    );

    await sessionRef.set(session.toMap());
    return session;
  }

  // Join an existing quiz session
  Future<void> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) {
        throw Exception('Quiz session not found');
      }

      final session = QuizSessionModel.fromMap(snapshot.data()!);
      if (!session.isWaiting) {
        throw Exception('Quiz session has already started');
      }

      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      updatedParticipants[userId] = QuizParticipant(
        userId: userId,
        userName: userName,
        hasJoined: true,
        joinedAt: DateTime.now(),
      );

      transaction.update(sessionRef, {
        'participants': updatedParticipants.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      });
    });
  }

  // Submit answers and update score
  Future<void> submitQuizAnswers({
    required String sessionId,
    required String userId,
    required int score,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) {
        throw Exception('Quiz session not found');
      }

      final session = QuizSessionModel.fromMap(snapshot.data()!);
      if (!session.isActive) {
        throw Exception('Quiz session is not active');
      }

      final participant = session.participants[userId];
      if (participant == null) {
        throw Exception('Participant not found in session');
      }

      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      updatedParticipants[userId] = participant.copyWith(score: score);

      transaction.update(sessionRef, {
        'participants': updatedParticipants.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      });
    });
  }

  // Start the quiz for all participants
  Future<void> startQuiz(String sessionId) async {
    await _firestore.doc('$_sessionsCollection/$sessionId').update({
      'status': QuizStatus.active.name,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // End the quiz session and finalize scores
  Future<void> endQuizSession(String sessionId) async {
    await _firestore.doc('$_sessionsCollection/$sessionId').update({
      'status': QuizStatus.completed.name,
    });
  }

  // Get real-time updates for a quiz session
  Stream<QuizSessionModel> getSessionUpdates(String sessionId) {
    return _firestore
        .doc('$_sessionsCollection/$sessionId')
        .snapshots()
        .map((snapshot) => QuizSessionModel.fromMap(snapshot.data()!));
  }

  // Get the current leaderboard for a session
  Future<List<QuizParticipant>> getSessionLeaderboard(String sessionId) async {
    final snapshot = await _firestore
        .doc('$_sessionsCollection/$sessionId')
        .get();
    if (!snapshot.exists) {
      throw Exception('Quiz session not found');
    }

    final session = QuizSessionModel.fromMap(snapshot.data()!);
    return session.sortedParticipantsByScore;
  }

  // Cancel a quiz session
  Future<void> cancelSession(String sessionId) async {
    await _firestore.doc('$_sessionsCollection/$sessionId').update({
      'status': QuizStatus.cancelled.name,
    });
  }

  // Get active sessions for a group
  Stream<List<QuizSessionModel>> getActiveGroupSessions(String groupId) {
    return _firestore
        .collection(_sessionsCollection)
        .where('groupId', isEqualTo: groupId)
        .where(
          'status',
          whereIn: [QuizStatus.waiting.name, QuizStatus.active.name],
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizSessionModel.fromMap(doc.data()))
              .toList(),
        );
  }
}
