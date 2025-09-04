import '../models/enums/connection_status.dart';

class QuizParticipant {
  final String userId;
  final String displayName;
  final ConnectionStatus connectionStatus;
  final DateTime? lastHeartbeat;
  final DateTime? disconnectedAt;
  final bool hasLockedAnswer;
  final int score;

  QuizParticipant({
    required this.userId,
    required this.displayName,
    this.connectionStatus = ConnectionStatus.offline,
    this.lastHeartbeat,
    this.disconnectedAt,
    this.hasLockedAnswer = false,
    this.score = 0,
  });

  QuizParticipant copyWith({
    String? userId,
    String? displayName,
    ConnectionStatus? connectionStatus,
    DateTime? lastHeartbeat,
    DateTime? disconnectedAt,
    bool? hasLockedAnswer,
    int? score,
  }) {
    return QuizParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      hasLockedAnswer: hasLockedAnswer ?? this.hasLockedAnswer,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'connectionStatus': connectionStatus.name,
      'lastHeartbeat': lastHeartbeat?.toIso8601String(),
      'disconnectedAt': disconnectedAt?.toIso8601String(),
      'hasLockedAnswer': hasLockedAnswer,
      'score': score,
    };
  }

  factory QuizParticipant.fromMap(Map<String, dynamic> map) {
    return QuizParticipant(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      connectionStatus: ConnectionStatus.values.byName(
        map['connectionStatus'] as String,
      ),
      lastHeartbeat: map['lastHeartbeat'] != null
          ? DateTime.parse(map['lastHeartbeat'] as String)
          : null,
      disconnectedAt: map['disconnectedAt'] != null
          ? DateTime.parse(map['disconnectedAt'] as String)
          : null,
      hasLockedAnswer: map['hasLockedAnswer'] as bool? ?? false,
      score: map['score'] as int? ?? 0,
    );
  }
}
