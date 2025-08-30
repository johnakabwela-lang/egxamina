import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/auth_service.dart';

class QuizPresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, Timer> _cleanupTimers = {};
  final Duration _heartbeatInterval = const Duration(seconds: 30);
  final Duration _timeoutDuration = const Duration(minutes: 2);

  static final QuizPresenceService _instance = QuizPresenceService._internal();
  factory QuizPresenceService() => _instance;
  QuizPresenceService._internal();

  // Start tracking presence for a user in a session
  Future<void> startTracking(String sessionId) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to track presence');
    }

    // Set initial presence
    await _setPresence(sessionId, user.uid);

    // Start heartbeat timer
    _heartbeatTimers[sessionId] = Timer.periodic(_heartbeatInterval, (_) {
      _setPresence(sessionId, user.uid);
    });

    // Start cleanup timer
    _startCleanupTimer(sessionId);
  }

  // Stop tracking presence
  void stopTracking(String sessionId) {
    _heartbeatTimers[sessionId]?.cancel();
    _heartbeatTimers.remove(sessionId);
    stopCleanup(sessionId);
  }

  // Set user presence
  Future<void> _setPresence(String sessionId, String userId) async {
    final presenceRef = _firestore
        .collection('quiz_sessions')
        .doc(sessionId)
        .collection('presence')
        .doc(userId);

    await presenceRef.set({
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  // Monitor participant presence
  Stream<Map<String, bool>> getPresenceUpdates(String sessionId) {
    return _firestore
        .collection('quiz_sessions')
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
              final isOnline = now.difference(lastSeen) < _timeoutDuration;
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
        .collection('quiz_sessions')
        .doc(sessionId)
        .collection('presence')
        .doc(userId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
    if (lastSeen == null) return false;

    return DateTime.now().difference(lastSeen) < _timeoutDuration;
  }

  // Clean up inactive users
  void _startCleanupTimer(String sessionId) {
    _cleanupTimers[sessionId] = Timer.periodic(_timeoutDuration, (_) async {
      final snapshot = await _firestore
          .collection('quiz_sessions')
          .doc(sessionId)
          .collection('presence')
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

        if (lastSeen != null && now.difference(lastSeen) > _timeoutDuration) {
          batch.update(doc.reference, {'isOnline': false});
        }
      }

      await batch.commit();
    });
  }

  // Stop cleanup timer
  void stopCleanup(String sessionId) {
    _cleanupTimers[sessionId]?.cancel();
    _cleanupTimers.remove(sessionId);
  }
}
