enum QuizStatus { waiting, active, completed, cancelled, expired }

enum ConnectionStatus { online, offline, reconnecting }

class QuizParticipant {
  final String userId;
  final String userName;
  final int score;
  final bool hasJoined;
  final DateTime? joinedAt;
  final ConnectionStatus connectionStatus;
  final DateTime? lastHeartbeat;
  final DateTime? disconnectedAt;
  final bool hasLockedAnswer;

  const QuizParticipant({
    required this.userId,
    required this.userName,
    this.score = 0,
    this.hasJoined = false,
    this.joinedAt,
    this.connectionStatus = ConnectionStatus.online,
    this.lastHeartbeat,
    this.disconnectedAt,
    this.hasLockedAnswer = false,
  });

  factory QuizParticipant.fromMap(Map<String, dynamic> map) {
    return QuizParticipant(
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      score: map['score'] as int? ?? 0,
      hasJoined: map['hasJoined'] as bool? ?? false,
      joinedAt: map['joinedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int)
          : null,
      connectionStatus: ConnectionStatus.values.firstWhere(
        (e) => e.name == (map['connectionStatus'] as String?),
        orElse: () => ConnectionStatus.offline,
      ),
      lastHeartbeat: map['lastHeartbeat'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastHeartbeat'] as int)
          : null,
      disconnectedAt: map['disconnectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['disconnectedAt'] as int)
          : null,
      hasLockedAnswer: map['hasLockedAnswer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'score': score,
      'hasJoined': hasJoined,
      'joinedAt': joinedAt?.millisecondsSinceEpoch,
      'connectionStatus': connectionStatus.name,
      'lastHeartbeat': lastHeartbeat?.millisecondsSinceEpoch,
      'disconnectedAt': disconnectedAt?.millisecondsSinceEpoch,
      'hasLockedAnswer': hasLockedAnswer,
    };
  }

  QuizParticipant copyWith({
    String? userId,
    String? userName,
    int? score,
    bool? hasJoined,
    DateTime? joinedAt,
    ConnectionStatus? connectionStatus,
    DateTime? lastHeartbeat,
    DateTime? disconnectedAt,
    bool? hasLockedAnswer,
  }) {
    return QuizParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      score: score ?? this.score,
      hasJoined: hasJoined ?? this.hasJoined,
      joinedAt: joinedAt ?? this.joinedAt,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      hasLockedAnswer: hasLockedAnswer ?? this.hasLockedAnswer,
    );
  }
}

class QuizSessionModel {
  final String id;
  final String groupId;
  final QuizStatus status;
  final Map<String, QuizParticipant> participants;
  final DateTime? startedAt;
  final String quizName;
  final String hostId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const QuizSessionModel({
    required this.id,
    required this.groupId,
    this.status = QuizStatus.waiting,
    required this.participants,
    required this.quizName,
    required this.hostId,
    required this.createdAt,
    this.startedAt,
    this.expiresAt,
  });

  factory QuizSessionModel.fromMap(Map<String, dynamic> map) {
    final participantsMap = <String, QuizParticipant>{};
    final participantsData = map['participants'] as Map<String, dynamic>? ?? {};

    for (final entry in participantsData.entries) {
      participantsMap[entry.key] = QuizParticipant.fromMap(
        entry.value as Map<String, dynamic>,
      );
    }

    return QuizSessionModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      status: QuizStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuizStatus.waiting,
      ),
      participants: participantsMap,
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int)
          : null,
      quizName: map['quizName'] as String,
      hostId: '${map['hostId']}',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final participantsMap = <String, dynamic>{};
    for (final entry in participants.entries) {
      participantsMap[entry.key] = entry.value.toMap();
    }

    return {
      'id': id,
      'groupId': groupId,
      'status': status.name,
      'participants': participantsMap,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'quizName': quizName,
    };
  }

  QuizSessionModel copyWith({
    String? id,
    String? groupId,
    QuizStatus? status,
    Map<String, QuizParticipant>? participants,
    DateTime? startedAt,
    String? quizName,
    String? hostId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return QuizSessionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      participants: participants != null
          ? Map.from(participants)
          : Map.from(this.participants),
      startedAt: startedAt ?? this.startedAt,
      quizName: quizName ?? this.quizName,
      hostId: hostId ?? this.hostId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizSessionModel &&
        other.id == id &&
        other.groupId == groupId &&
        other.status == status &&
        _mapEquals(other.participants, participants) &&
        other.startedAt == startedAt &&
        other.quizName == quizName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      status,
      Object.hashAll(
        participants.entries.map((e) => Object.hash(e.key, e.value)),
      ),
      startedAt,
      quizName,
    );
  }

  @override
  String toString() {
    return 'QuizSessionModel(id: $id, groupId: $groupId, status: $status, participants: $participants, startedAt: $startedAt, quizName: $quizName)';
  }

  // Helper methods
  bool get isActive => status == QuizStatus.active;
  bool get isWaiting => status == QuizStatus.waiting;
  bool get isCompleted => status == QuizStatus.completed;
  bool get isCancelled => status == QuizStatus.cancelled;
  bool get isExpired => status == QuizStatus.expired;

  bool hasExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get participantCount => participants.length;
  int get joinedParticipantCount =>
      participants.values.where((p) => p.hasJoined).length;

  List<QuizParticipant> get sortedParticipantsByScore {
    final participantList = participants.values.toList();
    participantList.sort((a, b) => b.score.compareTo(a.score));
    return participantList;
  }

  // Connection status helpers
  List<QuizParticipant> get onlineParticipants => participants.values
      .where((p) => p.connectionStatus == ConnectionStatus.online)
      .toList();

  List<QuizParticipant> get offlineParticipants => participants.values
      .where((p) => p.connectionStatus == ConnectionStatus.offline)
      .toList();

  List<QuizParticipant> get reconnectingParticipants => participants.values
      .where((p) => p.connectionStatus == ConnectionStatus.reconnecting)
      .toList();

  bool get hasMinimumOnlinePlayers => onlineParticipants.length >= 2;

  bool get shouldPauseQuiz => isActive && !hasMinimumOnlinePlayers;

  int get onlineCount => onlineParticipants.length;

  int get totalCount => participants.length;

  bool canStartQuiz() {
    return isWaiting && hasMinimumOnlinePlayers;
  }

  bool isReconnectionTimeoutExpired(String userId) {
    final participant = getParticipant(userId);
    if (participant?.disconnectedAt == null) return false;

    return DateTime.now().difference(participant!.disconnectedAt!) >
        const Duration(minutes: 1);
  }

  QuizParticipant? getParticipant(String userId) => participants[userId];

  // Helper method for map comparison
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
