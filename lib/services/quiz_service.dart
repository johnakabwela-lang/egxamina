import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quiz_session_model.dart';
import '../services/group_service.dart';
import './quiz_connection_service.dart';

class QuizService {
  // Singleton pattern
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QuizConnectionService _connectionService = QuizConnectionService();

  // Configuration
  final String _sessionsCollection = 'quizSessions';
  static const Duration waitingRoomTimeout = Duration(minutes: 5);
  static const Duration reconnectionTimeout = Duration(minutes: 2);

  // State management
  final Map<String, Timer> _expirationTimers = {};

  // MARK: - Session Management

  /// Validates if a user is a member of the specified group
  Future<bool> validateGroupMembership(String userId, String groupId) async {
    final userGroups = await GroupService.getUserGroups(userId);
    return userGroups.any((group) => group['id'] == groupId);
  }

  /// Gets active quiz sessions for a specific group
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

  /// Cleans up old sessions for a specific group
  Future<void> cleanUpOldSessions(String groupId) async {
    final snapshot = await _firestore
        .collection(_sessionsCollection)
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      final session = QuizSessionModel.fromMap(doc.data());
      if (session.hasExpired() ||
          session.status == QuizStatus.completed ||
          session.status == QuizStatus.cancelled) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  /// Creates a new multiplayer quiz session
  Future<QuizSessionModel> startMultiplayerSession({
    required String groupId,
    required String quizName,
    required String hostUserId,
    required String hostUserName,
  }) async {
    // Validate host's group membership
    final isMember = await validateGroupMembership(hostUserId, groupId);
    if (!isMember) {
      throw Exception(
        'You must be a member of this group to create a quiz session',
      );
    }

    // Check for existing active sessions in the group
    final existingSessions = await getActiveGroupSessions(groupId).first;
    if (existingSessions.isNotEmpty) {
      throw Exception('There is already an active quiz session in this group');
    }

    final sessionRef = _firestore.collection(_sessionsCollection).doc();
    final now = DateTime.now();
    final expiresAt = now.add(waitingRoomTimeout);

    final session = QuizSessionModel(
      id: sessionRef.id,
      groupId: groupId,
      quizName: quizName,
      hostId: hostUserId,
      status: QuizStatus.waiting,
      currentQuestionIndex: 0,
      participants: {
        hostUserId: QuizParticipant(
          userId: hostUserId,
          userName: hostUserName,
          score: 0,
          hasJoined: true,
          joinedAt: now,
          connectionStatus: ConnectionStatus.online,
          lastHeartbeat: now,
        ),
      },
      createdAt: now,
      startedAt: null,
      expiresAt: expiresAt,
    );

    await sessionRef.set(session.toMap());

    // Start tracking presence for host
    _connectionService.startHeartbeat(session.id, hostUserId);

    // Set up expiration timer
    _expirationTimers[session.id] = Timer(waitingRoomTimeout, () {
      _handleSessionExpiration(session.id);
    });

    return session;
  }

  /// Joins an existing quiz session
  Future<void> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) {
        throw Exception('Session not found');
      }

      final session = QuizSessionModel.fromMap(snapshot.data()!);

      // Validate session state
      if (!session.isWaiting) {
        throw Exception('Cannot join - session is no longer accepting players');
      }

      if (session.hasExpired()) {
        throw Exception('Session has expired');
      }

      // Validate group membership
      final isMember = await validateGroupMembership(userId, session.groupId);
      if (!isMember) {
        throw Exception('You must be a member of this group to join the quiz');
      }

      // Add participant
      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      updatedParticipants[userId] = QuizParticipant(
        userId: userId,
        userName: userName,
        score: 0,
        hasJoined: true,
        joinedAt: DateTime.now(),
        connectionStatus: ConnectionStatus.online,
        lastHeartbeat: DateTime.now(),
      );

      transaction.update(sessionRef, {
        'participants': updatedParticipants.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      });
    });

    // Start heartbeat for the new participant
    _connectionService.startHeartbeat(sessionId, userId);
  }

  /// Starts the quiz session (moves from waiting to active)
  Future<void> startQuizSession(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) {
        throw Exception('Session not found');
      }

      final session = QuizSessionModel.fromMap(snapshot.data()!);

      // Validate session state
      if (!session.isWaiting) {
        throw Exception('Quiz session is not in waiting state');
      }

      if (session.hasExpired()) {
        throw Exception('Session has expired');
      }

      if (!session.hasMinimumOnlinePlayers) {
        throw Exception('Need at least 2 online players to start the quiz');
      }

      // Update session state
      transaction.update(sessionRef, {
        'status': QuizStatus.active.name,
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });

    // Cancel expiration timer
    _expirationTimers[sessionId]?.cancel();
    _expirationTimers.remove(sessionId);
  }

  /// Cancels a quiz session
  Future<void> cancelSession(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) {
        throw Exception('Session not found');
      }

      final session = QuizSessionModel.fromMap(snapshot.data()!);

      // Only allow cancellation of waiting or active sessions
      if (!session.isWaiting && !session.isActive) {
        throw Exception('Cannot cancel a completed or expired session');
      }

      transaction.update(sessionRef, {'status': QuizStatus.cancelled.name});
    });

    // Clean up timers
    _expirationTimers[sessionId]?.cancel();
    _expirationTimers.remove(sessionId);
  }

  /// Completes a quiz session
  Future<void> completeSession(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');
    await sessionRef.update({'status': QuizStatus.completed.name});
  }

  // MARK: - Quiz Content Management

  /// Loads quiz questions from assets into the session
  Future<void> loadQuizIntoSession({
    required String sessionId,
    required String quizAssetPath,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    try {
      final String data = await rootBundle.loadString(quizAssetPath);
      final List<dynamic> questions = List<dynamic>.from(jsonDecode(data));

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) throw Exception('Session not found');

        transaction.update(sessionRef, {
          'questions': questions,
          'currentQuestionIndex': 0,
          'questionState': 'not_started',
          'answers': {},
        });
      });
    } catch (e) {
      throw Exception('Failed to load quiz: $e');
    }
  }

  /// Starts a specific question with timer (host only)
  Future<void> startQuizQuestion({
    required String sessionId,
    required int questionIndex,
    required int durationSeconds,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) throw Exception('Session not found');

      final data = snapshot.data()!;
      final questions = data['questions'] as List<dynamic>?;

      if (questions == null || questionIndex >= questions.length) {
        throw Exception('Invalid question index');
      }

      final now = DateTime.now();
      transaction.update(sessionRef, {
        'currentQuestionIndex': questionIndex,
        'questionState': 'active',
        'questionStartedAt': now.millisecondsSinceEpoch,
        'questionDuration': durationSeconds,
        'answers': {},
      });
    });
  }

  /// Submits a participant's answer for the current question
  Future<void> submitParticipantAnswer({
    required String sessionId,
    required String userId,
    required dynamic answer,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) throw Exception('Session not found');

      final data = snapshot.data()!;
      final questionState = data['questionState'] as String?;

      if (questionState != 'active') {
        throw Exception('No active question to answer');
      }

      final answers = Map<String, dynamic>.from(data['answers'] ?? {});
      answers[userId] = answer;

      transaction.update(sessionRef, {'answers': answers});
    });
  }

  /// Moves to the next question with score calculation
  Future<void> moveToNextQuestion(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) throw Exception('Session not found');

      final data = snapshot.data()!;
      final session = QuizSessionModel.fromMap(data);
      final questions = data['questions'] as List<dynamic>?;
      final currentIndex = data['currentQuestionIndex'] ?? 0;

      if (questions == null) {
        throw Exception('No questions loaded');
      }

      // Calculate scores for current question
      final answers = Map<String, dynamic>.from(data['answers'] ?? {});
      final correctAnswer = questions[currentIndex]['correctAnswer'];

      // Update participant scores
      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      answers.forEach((userId, userAnswer) {
        if (updatedParticipants[userId] != null) {
          final participant = updatedParticipants[userId]!;
          final currentScore = participant.score ?? 0;
          final isCorrect = userAnswer == correctAnswer;
          final newScore = currentScore + (isCorrect ? 1 : 0);
          updatedParticipants[userId] = participant.copyWith(score: newScore);
        }
      });

      // Check if this was the last question
      if (currentIndex + 1 >= questions.length) {
        // Quiz is complete
        transaction.update(sessionRef, {
          'status': QuizStatus.completed.name,
          'questionState': 'finished',
          'participants': updatedParticipants.map(
            (k, v) => MapEntry(k, v.toMap()),
          ),
        });
        return;
      }

      // Move to next question
      transaction.update(sessionRef, {
        'currentQuestionIndex': currentIndex + 1,
        'questionState': 'not_started',
        'answers': {},
        'participants': updatedParticipants.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      });
    });
  }

  /// Finishes the quiz and calculates final scores
  Future<void> finishQuiz(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) throw Exception('Session not found');

      final data = snapshot.data()!;
      final session = QuizSessionModel.fromMap(data);
      final questions = data['questions'] as List<dynamic>?;
      final allAnswers = data['allAnswers'] as Map<String, dynamic>?;

      // Calculate final scores
      Map<String, int> finalScores = {};
      if (questions != null && allAnswers != null) {
        for (final entry in allAnswers.entries) {
          final userId = entry.key;
          final userAnswers = entry.value as List?;
          int score = 0;

          if (userAnswers != null) {
            for (
              int i = 0;
              i < userAnswers.length && i < questions.length;
              i++
            ) {
              final question = questions[i];
              if (userAnswers[i] == question['correctAnswer']) {
                score++;
              }
            }
          }
          finalScores[userId] = score;
        }
      }

      // Update participants with final scores
      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      finalScores.forEach((userId, score) {
        if (updatedParticipants[userId] != null) {
          updatedParticipants[userId] = updatedParticipants[userId]!.copyWith(
            score: score,
          );
        }
      });

      transaction.update(sessionRef, {
        'status': QuizStatus.completed.name,
        'questionState': 'finished',
        'participants': updatedParticipants.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
        'finalScores': finalScores,
      });
    });
  }

  // MARK: - Connection Management

  /// Handles participant disconnection
  Future<void> handleParticipantDisconnect(
    String sessionId,
    String userId,
  ) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final session = QuizSessionModel.fromMap(snapshot.data()!);
      final participant = session.getParticipant(userId);
      if (participant == null) return;

      final updatedParticipant = participant.copyWith(
        connectionStatus: ConnectionStatus.reconnecting,
        disconnectedAt: DateTime.now(),
      );

      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      updatedParticipants[userId] = updatedParticipant;

      transaction.update(sessionRef, {
        'participants': updatedParticipants.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      });

      // Auto-pause quiz if minimum players not met
      if (session.shouldPauseQuiz) {
        transaction.update(sessionRef, {'status': QuizStatus.waiting.name});
      }
    });

    _connectionService.startReconnectionTimer(sessionId, userId);
  }

  /// Handles participant reconnection
  Future<void> handleParticipantReconnect(
    String sessionId,
    String userId,
  ) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final session = QuizSessionModel.fromMap(snapshot.data()!);
      final participant = session.getParticipant(userId);
      if (participant == null) return;

      final updatedParticipant = participant.copyWith(
        connectionStatus: ConnectionStatus.online,
        lastHeartbeat: DateTime.now(),
        disconnectedAt: null,
      );

      final updatedParticipants = Map<String, QuizParticipant>.from(
        session.participants,
      );
      updatedParticipants[userId] = updatedParticipant;

      transaction.update(sessionRef, {
        'participants': updatedParticipants.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      });
    });

    // Restart heartbeat monitoring
    _connectionService.stopReconnectionTimer(sessionId, userId);
    _connectionService.startHeartbeat(sessionId, userId);
  }

  /// Updates a participant's connection status
  Future<void> updateParticipantConnectionStatus(
    String sessionId,
    String userId,
    bool isConnected,
  ) async {
    await _firestore.doc('$_sessionsCollection/$sessionId').update({
      'participants.$userId.connectionStatus': isConnected
          ? ConnectionStatus.online.name
          : ConnectionStatus.offline.name,
      'participants.$userId.lastHeartbeat': FieldValue.serverTimestamp(),
    });
  }

  /// Clean up when leaving a session
  void leaveSession(String sessionId, String userId) {
    _connectionService.stopHeartbeat(sessionId, userId);
  }

  // MARK: - Utility Methods

  /// Gets a real-time stream of session updates
  Stream<QuizSessionModel> getSessionUpdates(String sessionId) {
    return _firestore
        .doc('$_sessionsCollection/$sessionId')
        .snapshots()
        .map((doc) => QuizSessionModel.fromMap(doc.data()!));
  }

  /// Gets a snapshot of the current session state
  Future<QuizSessionModel> getSessionSnapshot(String sessionId) async {
    final doc = await _firestore.doc('$_sessionsCollection/$sessionId').get();
    if (!doc.exists) throw Exception('Session not found');
    return QuizSessionModel.fromMap(doc.data()!);
  }

  /// Checks if a session can be joined
  Future<bool> canJoinSession(String sessionId) async {
    final doc = await _firestore.doc('$_sessionsCollection/$sessionId').get();
    if (!doc.exists) return false;

    final session = QuizSessionModel.fromMap(doc.data()!);
    return session.status == QuizStatus.waiting && !session.hasExpired();
  }

  /// Pings the session to check connectivity
  Future<void> pingSession(String sessionId) async {
    final ref = _firestore.doc('$_sessionsCollection/$sessionId');
    final doc = await ref.get();
    if (!doc.exists) {
      throw Exception('Session not found');
    }
  }

  // MARK: - Private Methods

  /// Handles session expiration
  Future<void> _handleSessionExpiration(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) return;

        final session = QuizSessionModel.fromMap(snapshot.data()!);

        // Only expire sessions that are still in waiting state
        if (session.isWaiting) {
          transaction.update(sessionRef, {
            'status': QuizStatus.expired.name,
            'expiredAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
    } catch (e) {
      print('Error handling session expiration: $e');
    }

    // Clean up timer
    _expirationTimers.remove(sessionId);
  }

  /// Cleans up all timers and connections
  void dispose() {
    for (final timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
  }
}
