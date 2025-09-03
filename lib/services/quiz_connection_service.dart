import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_session_model.dart';
import '../services/auth_service.dart';

class QuizConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, Timer> _reconnectionTimers = {};
  final Map<String, Timer> _cleanupTimers = {};

  static const Duration heartbeatInterval = Duration(seconds: 15);
  static const Duration reconnectionTimeout = Duration(minutes: 1);
  static const Duration offlineThreshold = Duration(seconds: 30);
  static const Duration presenceTimeout = Duration(minutes: 2);

  static final QuizConnectionService _instance =
      QuizConnectionService._internal();
  factory QuizConnectionService() => _instance;
  QuizConnectionService._internal();

  // Start tracking presence and connection for a user in a session
  Future<void> startTracking(String sessionId) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to track presence');
    }

    await startHeartbeat(sessionId, user.uid);
    _startCleanupTimer(sessionId);
  }

  // Stop all tracking for a session
  void stopTracking(String sessionId) {
    final user = AuthService.currentUser;
    if (user != null) {
      stopHeartbeat(sessionId, user.uid);
    }
    stopCleanup(sessionId);
  }

  // Start heartbeat for a participant
  Future<void> startHeartbeat(String sessionId, String userId) async {
    stopHeartbeat(sessionId, userId); // Clear any existing timer

    // Set initial presence
    await _sendHeartbeat(sessionId, userId);

    // Start periodic heartbeat
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
    try {
      // Update main session document
      final sessionRef = _firestore.doc('quizSessions/$sessionId');
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) return;

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

      // Also update presence subcollection for real-time monitoring
      final presenceRef = _firestore
          .collection('quizSessions')
          .doc(sessionId)
          .collection('presence')
          .doc(userId);

      await presenceRef.set({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      });
    } catch (e) {
      print('Error sending heartbeat: $e');
    }
  }

  // Handle graceful leave (when user navigates back properly)
  Future<void> leaveSession(String sessionId, String userId) async {
    try {
      // Stop all timers for this user
      stopHeartbeat(sessionId, userId);
      stopReconnectionTimer(sessionId, userId);

      final sessionRef = _firestore.doc('quizSessions/$sessionId');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(sessionRef);
        if (!snapshot.exists) return;

        final session = QuizSessionModel.fromMap(snapshot.data()!);
        final participant = session.getParticipant(userId);
        if (participant == null) return;

        // Check if user is the host and quiz hasn't started
        if (session.hostId == userId && session.status == QuizStatus.waiting) {
          // Transfer host to another participant or cancel session
          final otherParticipants = session.participants.values
              .where(
                (p) =>
                    p.userId != userId &&
                    p.connectionStatus == ConnectionStatus.online,
              )
              .toList();

          if (otherParticipants.isNotEmpty) {
            // Transfer host to first online participant
            final newHost = otherParticipants.first;
            final updatedParticipants = Map<String, QuizParticipant>.from(
              session.participants,
            );
            updatedParticipants.remove(userId);

            transaction.update(sessionRef, {
              'hostId': newHost.userId,
              'participants': updatedParticipants.map(
                (key, value) => MapEntry(key, value.toMap()),
              ),
            });
          } else {
            // No other participants, cancel the session
            transaction.update(sessionRef, {
              'status': QuizStatus.cancelled.name,
              'cancelledAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Regular participant leaving or host leaving during active quiz
          final updatedParticipants = Map<String, QuizParticipant>.from(
            session.participants,
          );

          if (session.status == QuizStatus.waiting) {
            // Remove participant completely if quiz hasn't started
            updatedParticipants.remove(userId);
          } else {
            // Mark as offline if quiz is active
            updatedParticipants[userId] = participant.copyWith(
              connectionStatus: ConnectionStatus.offline,
              disconnectedAt: DateTime.now(),
            );
          }

          transaction.update(sessionRef, {
            'participants': updatedParticipants.map(
              (key, value) => MapEntry(key, value.toMap()),
            ),
          });

          // Check if we need to pause active quiz due to insufficient players
          if (session.isActive &&
              !_hasMinimumOnlinePlayers(updatedParticipants)) {
            transaction.update(sessionRef, {'shouldPauseQuiz': true});
          }
        }
      });

      // Remove from presence subcollection
      await _firestore
          .collection('quizSessions')
          .doc(sessionId)
          .collection('presence')
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error leaving session: $e');
      rethrow;
    }
  }

  // Check if there are minimum online players
  bool _hasMinimumOnlinePlayers(Map<String, QuizParticipant> participants) {
    final onlineCount = participants.values
        .where((p) => p.connectionStatus == ConnectionStatus.online)
        .length;
    return onlineCount >= 2; // Minimum 2 players for quiz
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
        if (!snapshot.exists) return;

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
        if (!_hasMinimumOnlinePlayers(updatedParticipants)) {
          transaction.update(sessionRef, {'shouldPauseQuiz': true});
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
        if (!snapshot.exists) return;

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

  // Monitor participant presence using subcollection
  Stream<Map<String, bool>> getPresenceUpdates(String sessionId) {
    return _firestore
        .collection('quizSessions')
        .doc(sessionId)
        .collection('presence')
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final presence = <String, bool>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

            if (lastSeen != null) {
              final isOnline = now.difference(lastSeen) < presenceTimeout;
              presence[doc.id] = isOnline;
            } else {
              presence[doc.id] = false;
            }
          }

          return presence;
        });
  }

  // Check if a specific user is online
  Future<bool> isUserOnline(String sessionId, String userId) async {
    final doc = await _firestore
        .collection('quizSessions')
        .doc(sessionId)
        .collection('presence')
        .doc(userId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
    if (lastSeen == null) return false;

    return DateTime.now().difference(lastSeen) < presenceTimeout;
  }

  // Clean up inactive users from presence subcollection
  void _startCleanupTimer(String sessionId) {
    _cleanupTimers[sessionId] = Timer.periodic(presenceTimeout, (_) async {
      try {
        final snapshot = await _firestore
            .collection('quizSessions')
            .doc(sessionId)
            .collection('presence')
            .get();

        final batch = _firestore.batch();
        final now = DateTime.now();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

          if (lastSeen != null && now.difference(lastSeen) > presenceTimeout) {
            batch.update(doc.reference, {'isOnline': false});
          }
        }

        await batch.commit();
      } catch (e) {
        print('Error in cleanup timer: $e');
      }
    });
  }

  // Stop cleanup timer
  void stopCleanup(String sessionId) {
    _cleanupTimers[sessionId]?.cancel();
    _cleanupTimers.remove(sessionId);
  }

  // Clean up all timers for a specific user session
  void dispose(String sessionId, String userId) {
    stopHeartbeat(sessionId, userId);
    stopReconnectionTimer(sessionId, userId);
  }

  // Clean up all timers for a session
  void disposeSession(String sessionId) {
    // Remove all timers related to this session
    final keysToRemove = <String>[];

    for (final key in _heartbeatTimers.keys) {
      if (key.startsWith('$sessionId:')) {
        _heartbeatTimers[key]?.cancel();
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _heartbeatTimers.remove(key);
    }

    keysToRemove.clear();
    for (final key in _reconnectionTimers.keys) {
      if (key.startsWith('$sessionId:')) {
        _reconnectionTimers[key]?.cancel();
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _reconnectionTimers.remove(key);
    }

    stopCleanup(sessionId);
  }
}
