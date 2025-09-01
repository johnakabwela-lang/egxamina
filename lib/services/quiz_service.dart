import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/quiz_session_model.dart';
import '../services/group_service.dart';
import 'quiz_connection_service.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _sessionsCollection = 'quizSessions';
  static const Duration waitingRoomTimeout = Duration(minutes: 5);
  static const Duration reconnectionTimeout = Duration(minutes: 2);

  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  final QuizConnectionService _connectionService = QuizConnectionService();
  final Map<String, Timer> _expirationTimers = {};

  QuizService._internal();

  // Validate user's group membership
  Future<bool> validateGroupMembership(String userId, String groupId) async {
    final userGroups = await GroupService.getUserGroups(userId);
    return userGroups.any((group) => group['id'] == groupId);
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

  // Start a new multiplayer quiz session
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
      status: QuizStatus.waiting,
      participants: {
        hostUserId: QuizParticipant(
          userId: hostUserId,
          userName: hostUserName,
          hasJoined: true,
          joinedAt: now,
          connectionStatus: ConnectionStatus.online,
          lastHeartbeat: now,
        ),
      },
      startedAt: null,
      quizName: quizName,
      hostId: hostUserId,
      createdAt: now,
      expiresAt: expiresAt,
    );

    await sessionRef.set(session.toMap());

    // Start tracking presence
    _connectionService.startHeartbeat(session.id, hostUserId);

    // Set up expiration timer
    _expirationTimers[session.id] = Timer(waitingRoomTimeout, () {
      _handleSessionExpiration(session.id);
    });

    return session;
  }

  // Handle session expiration
  Future<void> _handleSessionExpiration(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) return;

        final session = QuizSessionModel.fromMap(snapshot.data()!);

        // Only expire sessions that are still in waiting state
        if (session.isWaiting) {
          transaction.update(sessionRef, {'status': QuizStatus.expired.name});
        }
      });
    } catch (e) {
      print('Error handling session expiration: $e');
    }
  }

  // Join an existing quiz session
  Future<void> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
  }) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) {
          throw Exception('Session not found');
        }

        final session = QuizSessionModel.fromMap(snapshot.data()!);

        // Validate session state
        if (!session.isWaiting) {
          throw Exception(
            'Cannot join - session is no longer accepting players',
          );
        }

        if (session.hasExpired()) {
          throw Exception('Session has expired');
        }

        // Validate group membership
        final isMember = await validateGroupMembership(userId, session.groupId);
        if (!isMember) {
          throw Exception(
            'You must be a member of this group to join the quiz',
          );
        }

        // Add participant
        final updatedParticipants = Map<String, QuizParticipant>.from(
          session.participants,
        );
        updatedParticipants[userId] = QuizParticipant(
          userId: userId,
          userName: userName,
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
    } catch (e) {
      rethrow;
    }
  }

  // Start the quiz
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
        throw Exception('Not enough online players to start the quiz');
      }

      // Update session state
      transaction.update(sessionRef, {
        'status': QuizStatus.active.name,
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Cancel expiration timer
      _expirationTimers[sessionId]?.cancel();
      _expirationTimers.remove(sessionId);
    });
  }

  // Cancel a quiz session
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

      // Update session state
      transaction.update(sessionRef, {'status': QuizStatus.cancelled.name});

      // Clean up timers
      _expirationTimers[sessionId]?.cancel();
      _expirationTimers.remove(sessionId);
    });
  }

  // Get session updates stream
  Stream<QuizSessionModel> getSessionUpdates(String sessionId) {
    return _firestore
        .doc('$_sessionsCollection/$sessionId')
        .snapshots()
        .map((doc) => QuizSessionModel.fromMap(doc.data()!));
  }

  // Clean up when leaving a session
  void leaveSession(String sessionId, String userId) {
    _connectionService.stopHeartbeat(sessionId, userId);
  }

  // Handle session completion
  Future<void> completeSession(String sessionId) async {
    final sessionRef = _firestore.doc('$_sessionsCollection/$sessionId');
    await sessionRef.update({'status': QuizStatus.completed.name});
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

      transaction.update(sessionRef, {
        'status': QuizStatus.active.name,
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Cancel expiration timer
      _expirationTimers[sessionId]?.cancel();
      _expirationTimers.remove(sessionId);
    });
  }

  // Handle participant disconnect/reconnect
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

  // Handle participant reconnect
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
}
