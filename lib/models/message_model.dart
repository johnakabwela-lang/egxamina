enum MessageType { text, reaction }

class MessageModel {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final MessageType type;

  const MessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name,
    };
  }

  MessageModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    DateTime? timestamp,
    MessageType? type,
  }) {
    return MessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, userName, message, timestamp, type);
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, userId: $userId, userName: $userName, message: $message, timestamp: $timestamp, type: $type)';
  }

  // Helper method to check if message is a reaction
  bool get isReaction => type == MessageType.reaction;

  // Helper method to check if message is text
  bool get isText => type == MessageType.text;
}
