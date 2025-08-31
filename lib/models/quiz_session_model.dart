enum QuizStatus { waiting, active, completed, cancelled }

class QuizParticipant {
  final String userId;
  final String userName;
  final int score;
  final bool hasJoined;
  final DateTime? joinedAt;

  const QuizParticipant({
    required this.userId,
    required this.userName,
    this.score = 0,
    this.hasJoined = false,
    this.joinedAt,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'score': score,
      'hasJoined': hasJoined,
      'joinedAt': joinedAt?.millisecondsSinceEpoch,
    };
  }

  QuizParticipant copyWith({
    String? userId,
    String? userName,
    int? score,
    bool? hasJoined,
    DateTime? joinedAt,
  }) {
    return QuizParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      score: score ?? this.score,
      hasJoined: hasJoined ?? this.hasJoined,
      joinedAt: joinedAt ?? this.joinedAt,
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
  final String? hostId;

  const QuizSessionModel({
    required this.id,
    required this.groupId,
    this.status = QuizStatus.waiting,
    required this.participants,
    this.startedAt,
    required this.quizName,
    required this.hostId,
    required String hostUserId,
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
      hostUserId: '',
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
      hostUserId: '',
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

  int get participantCount => participants.length;
  int get joinedParticipantCount =>
      participants.values.where((p) => p.hasJoined).length;

  List<QuizParticipant> get sortedParticipantsByScore {
    final participantList = participants.values.toList();
    participantList.sort((a, b) => b.score.compareTo(a.score));
    return participantList;
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
