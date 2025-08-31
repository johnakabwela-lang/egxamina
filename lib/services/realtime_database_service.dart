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

  // Public method to get group activity reference
  static DatabaseReference getGroupActivityReference(String groupId) =>
      _getGroupActivityRef(groupId);

  // Group member presence reference
  static DatabaseReference _getGroupMemberPresenceRef(
    String groupId,
    String userId,
  ) => _getGroupActivityRef(groupId).child('activeMembers').child(userId);

  /// Initialize presence tracking for a user in a group
  static Future<void> initializeGroupPresence(
    String groupId,
    String userId,
  ) async {
    final memberPresenceRef = _getGroupMemberPresenceRef(groupId, userId);
    final userStatusRef = _getUserStatusRef(userId);
    final groupActivityRef = _getGroupActivityRef(groupId);

    // Set up disconnect cleanup
    await memberPresenceRef.onDisconnect().remove();

    // Update user's group presence status
    await memberPresenceRef.set({
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
      'joinedAt': ServerValue.timestamp,
    });

    // Update group's last activity
    await groupActivityRef.update({'lastActivity': ServerValue.timestamp});

    // Set up status listener
    userStatusRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final status = (event.snapshot.value as Map)['state'];
        memberPresenceRef.update({
          'status': status,
          'lastSeen': ServerValue.timestamp,
        });
      }
    });
  }

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

  // Get current user ID (utility method using the _auth field)
  static String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;
}
