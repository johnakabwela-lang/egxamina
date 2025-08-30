import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get database reference
  static DatabaseReference get databaseRef => _database.ref();

  // User presence reference
  static DatabaseReference _getUserPresenceRef(String uid) =>
      databaseRef.child('user_presence').child(uid);

  // User status reference
  static DatabaseReference _getUserStatusRef(String uid) =>
      databaseRef.child('users').child(uid).child('status');

  // Group activity reference
  static DatabaseReference _getGroupActivityRef(String groupId) =>
      databaseRef.child('group_activity').child(groupId);

  // Initialize user presence
  static Future<void> initializeUserPresence(String uid) async {
    final userStatusRef = _getUserStatusRef(uid);
    final userPresenceRef = _getUserPresenceRef(uid);

    // Create an online status object
    final status = {
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
      'deviceInfo': {
        'platform': 'Flutter',
        'lastActivity': ServerValue.timestamp,
      },
    };

    // When app disconnects, update the user status
    await userStatusRef.onDisconnect().update({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });

    // Set the initial online status
    await userStatusRef.set(status);
    await userPresenceRef.set(true);
  }

  // Update user activity timestamp
  static Future<void> updateUserActivity(String uid) async {
    await _getUserStatusRef(
      uid,
    ).child('deviceInfo').update({'lastActivity': ServerValue.timestamp});
  }

  // Update group activity
  static Future<void> updateGroupActivity(String groupId) async {
    await _getGroupActivityRef(
      groupId,
    ).update({'lastActivity': ServerValue.timestamp});
  }

  // Get user online status stream
  static Stream<bool> getUserOnlineStatus(String uid) {
    return _getUserPresenceRef(uid).onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  // Get group activity stream
  static Stream<DateTime> getGroupLastActivity(String groupId) {
    return _getGroupActivityRef(groupId).child('lastActivity').onValue.map((
      event,
    ) {
      final timestamp = event.snapshot.value as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    });
  }
}
