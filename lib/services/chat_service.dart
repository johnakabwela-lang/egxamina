import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the chats node in Firebase Realtime Database
  DatabaseReference _getChatsRef() => _database.ref('chats');

  // Reference to a specific group's chat
  DatabaseReference _getGroupChatRef(String groupId) =>
      _getChatsRef().child(groupId);

  // Reference to typing indicators
  DatabaseReference _getTypingRef(String groupId) =>
      _database.ref('typing').child(groupId);

  // Send a text message to a group chat
  Future<void> sendMessage({
    required String groupId,
    required String content,
    String? replyToId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageRef = _getGroupChatRef(groupId).push();
    final message = MessageModel(
      id: messageRef.key!,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      message: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    await messageRef.set(message.toMap());
  }

  // Add an emoji reaction to a message
  Future<void> addReaction({
    required String groupId,
    required String messageId,
    required String emoji,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reactionMessage = MessageModel(
      id: '${messageId}_${user.uid}_reaction',
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      message: emoji,
      timestamp: DateTime.now(),
      type: MessageType.reaction,
    );

    await _getGroupChatRef(groupId)
        .child(messageId)
        .child('reactions')
        .child(user.uid)
        .set(reactionMessage.toMap());
  }

  // Remove an emoji reaction from a message
  Future<void> removeReaction({
    required String groupId,
    required String messageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final reactionRef = _getGroupChatRef(
      groupId,
    ).child(messageId).child('reactions').child(user.uid);

    await reactionRef.remove();
  }

  // Listen to messages in real-time for a specific group
  Stream<List<MessageModel>> listenToGroupMessages(String groupId) {
    return _getGroupChatRef(groupId).orderByChild('timestamp').onValue.map((
      event,
    ) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      final messages = data.entries.map((entry) {
        final messageData = Map<String, dynamic>.from(entry.value);
        messageData['id'] = entry.key;
        return MessageModel.fromMap(messageData);
      }).toList();

      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  // Delete a message (only if user is the author)
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageRef = _getGroupChatRef(groupId).child(messageId);
    final snapshot = await messageRef.get();

    if (!snapshot.exists) throw Exception('Message not found');

    final messageData = snapshot.value as Map<dynamic, dynamic>;
    if (messageData['senderId'] != user.uid) {
      throw Exception('Only the message author can delete the message');
    }

    await messageRef.remove();
  }

  // Get message history for a group with pagination
  Future<List<MessageModel>> getMessageHistory({
    required String groupId,
    int limit = 50,
    String? endAtMessageId,
  }) async {
    Query query = _getGroupChatRef(
      groupId,
    ).orderByChild('timestamp').limitToLast(limit);

    if (endAtMessageId != null) {
      final endAtMessage = await _getGroupChatRef(
        groupId,
      ).child(endAtMessageId).get();

      if (endAtMessage.exists) {
        final messageData = endAtMessage.value as Map<dynamic, dynamic>;
        final timestamp = (messageData['timestamp'] as int);
        query = query.endAt(timestamp, key: endAtMessageId);
      }
    }

    final snapshot = await query.get();
    if (!snapshot.exists) return [];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final messages = data.entries.map((entry) {
      final messageData = Map<String, dynamic>.from(entry.value);
      messageData['id'] = entry.key;
      return MessageModel.fromMap(messageData);
    }).toList();

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages;
  }

  // Set typing indicator
  Future<void> setTypingStatus({
    required String groupId,
    required bool isTyping,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (isTyping) {
      await _getTypingRef(groupId).child(user.uid).set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'displayName': user.displayName,
      });
    } else {
      await _getTypingRef(groupId).child(user.uid).remove();
    }
  }

  // Listen to typing indicators
  Stream<List<String>> listenToTypingIndicators(String groupId) {
    return _getTypingRef(groupId).onValue.map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return [];

      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Filter out old typing indicators (older than 5 seconds)
      final now = DateTime.now().millisecondsSinceEpoch;
      return data.entries
          .where(
            (entry) =>
                entry.key != currentUser.uid &&
                now - (entry.value['timestamp'] as int) < 5000,
          )
          .map((entry) => entry.value['displayName'] as String)
          .toList();
    });
  }
}
