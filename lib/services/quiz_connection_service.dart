import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_session_model.dart';

class QuizConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, Timer> _reconnectionTimers = {};

  static const Duration heartbeatInterval = Duration(seconds: 15);
  static const Duration reconnectionTimeout = Duration(minutes: 1);
  static const Duration offlineThreshold = Duration(seconds: 30);

  static final QuizConnectionService _instance =
      QuizConnectionService._internal();
  factory QuizConnectionService() => _instance;
  QuizConnectionService._internal();

  // Start heartbeat for a participant
  void startHeartbeat(String sessionId, String userId) {
    stopHeartbeat(sessionId, userId); // Clear any existing timer

    _heartbeatTimers['$sessionId:$userId'] = Timer.periodic(
      heartbeatInterval,
      (_) => _sendHeartbeat(sessionId, userId),
    );
  }

  // Stop heartbeat for a participant
  void stopHeartbeat(String sessionId, String userId) {
    _heartbeatTimers['$sessionId:$userId']?.cancel();
    _heartbeatTimers.remove('$sessionId:$userId');
  }

  // Send heartbeat to Firebase
  Future<void> _sendHeartbeat(String sessionId, String userId) async {
    final sessionRef = _firestore.doc('quizSessions/$sessionId');

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        final session = QuizSessionModel.fromMap(snapshot.data()!);

        final participant = session.getParticipant(userId);
        if (participant == null) return;

        final updatedParticipant = participant.copyWith(
          lastHeartbeat: DateTime.now(),
          connectionStatus: ConnectionStatus.online,
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
    } catch (e) {
      print('Error sending heartbeat: $e');
    }
  }

  // Start reconnection timer for a participant
  void startReconnectionTimer(String sessionId, String userId) {
    stopReconnectionTimer(sessionId, userId);

    _reconnectionTimers['$sessionId:$userId'] = Timer(
      reconnectionTimeout,
      () => _handleReconnectionTimeout(sessionId, userId),
    );
  }

  // Stop reconnection timer
  void stopReconnectionTimer(String sessionId, String userId) {
    _reconnectionTimers['$sessionId:$userId']?.cancel();
    _reconnectionTimers.remove('$sessionId:$userId');
  }

  // Handle reconnection timeout
  Future<void> _handleReconnectionTimeout(
    String sessionId,
    String userId,
  ) async {
    final sessionRef = _firestore.doc('quizSessions/$sessionId');

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        final session = QuizSessionModel.fromMap(snapshot.data()!);

        if (!session.isActive)
          return; // Only handle timeout for active sessions

        final participant = session.getParticipant(userId);
        if (participant == null) return;

        final updatedParticipant = participant.copyWith(
          connectionStatus: ConnectionStatus.offline,
          hasLockedAnswer: true, // Lock answers on timeout
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
        if (!session.hasMinimumOnlinePlayers) {
          transaction.update(sessionRef, {'status': QuizStatus.waiting.name});
        }
      });
    } catch (e) {
      print('Error handling reconnection timeout: $e');
    }
  }

  // Check participant connection status
  Future<void> checkConnectionStatus(String sessionId) async {
    final sessionRef = _firestore.doc('quizSessions/$sessionId');
    final now = DateTime.now();

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        final session = QuizSessionModel.fromMap(snapshot.data()!);

        final updatedParticipants = Map<String, QuizParticipant>.from(
          session.participants,
        );
        var needsUpdate = false;

        for (final entry in session.participants.entries) {
          final participant = entry.value;
          final lastHeartbeat = participant.lastHeartbeat;

          if (lastHeartbeat == null) continue;

          final timeSinceLastHeartbeat = now.difference(lastHeartbeat);
          if (timeSinceLastHeartbeat > offlineThreshold &&
              participant.connectionStatus == ConnectionStatus.online) {
            // Mark as reconnecting if recently online
            updatedParticipants[entry.key] = participant.copyWith(
              connectionStatus: ConnectionStatus.reconnecting,
              disconnectedAt: now,
            );
            needsUpdate = true;

            // Start reconnection timer
            startReconnectionTimer(sessionId, participant.userId);
          }
        }

        if (needsUpdate) {
          transaction.update(sessionRef, {
            'participants': updatedParticipants.map(
              (key, value) => MapEntry(key, value.toMap()),
            ),
          });
        }
      });
    } catch (e) {
      print('Error checking connection status: $e');
    }
  }

  // Clean up all timers
  void dispose(String sessionId, String userId) {
    stopHeartbeat(sessionId, userId);
    stopReconnectionTimer(sessionId, userId);
  }
}
