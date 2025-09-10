import 'package:cloud_firestore/cloud_firestore.dart';

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
      joinedAt: _parseTimestamp(map['joinedAt']),
      connectionStatus: ConnectionStatus.values.firstWhere(
        (e) => e.name == (map['connectionStatus'] as String?),
        orElse: () => ConnectionStatus.offline,
      ),
      lastHeartbeat: _parseTimestamp(map['lastHeartbeat']),
      disconnectedAt: _parseTimestamp(map['disconnectedAt']),
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

  // Static helper method to parse timestamps
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
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

  // Quiz game data fields
  final String subject;
  final String fileName;
  final List<Map<String, dynamic>> questions;
  final int currentQuestionIndex;
  final DateTime? currentQuestionStartTime;
  final int questionTimeLimit;
  final Map<String, List<int>> participantAnswers;

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
    this.subject = '',
    this.fileName = '',
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.currentQuestionStartTime,
    this.questionTimeLimit = 30,
    this.participantAnswers = const {},
  });

  factory QuizSessionModel.fromMap(Map<String, dynamic> map) {
    final participantsMap = <String, QuizParticipant>{};
    final participantsData = map['participants'] as Map<String, dynamic>? ?? {};

    for (final entry in participantsData.entries) {
      participantsMap[entry.key] = QuizParticipant.fromMap(
        entry.value as Map<String, dynamic>,
      );
    }

    // Parse participant answers
    final participantAnswersMap = <String, List<int>>{};
    final participantAnswersData =
        map['participantAnswers'] as Map<String, dynamic>? ?? {};

    for (final entry in participantAnswersData.entries) {
      final answersList = entry.value as List<dynamic>? ?? [];
      participantAnswersMap[entry.key] = answersList
          .map((e) => e as int)
          .toList();
    }

    return QuizSessionModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      status: QuizStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuizStatus.waiting,
      ),
      participants: participantsMap,
      startedAt: _parseTimestamp(map['startedAt']),
      quizName: map['quizName'] as String,
      hostId: '${map['hostId']}',
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      expiresAt: _parseTimestamp(map['expiresAt']),
      subject: map['subject'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      currentQuestionIndex: map['currentQuestionIndex'] as int? ?? 0,
      currentQuestionStartTime: _parseTimestamp(
        map['currentQuestionStartTime'],
      ),
      questionTimeLimit: map['questionTimeLimit'] as int? ?? 30,
      participantAnswers: participantAnswersMap,
    );
  }

  Map<String, dynamic> toMap() {
    final participantsMap = <String, dynamic>{};
    for (final entry in participants.entries) {
      participantsMap[entry.key] = entry.value.toMap();
    }

    // Convert participant answers to serializable format
    final participantAnswersMap = <String, dynamic>{};
    for (final entry in participantAnswers.entries) {
      participantAnswersMap[entry.key] = entry.value;
    }

    return {
      'id': id,
      'groupId': groupId,
      'status': status.name,
      'participants': participantsMap,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'quizName': quizName,
      'hostId': hostId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'subject': subject,
      'fileName': fileName,
      'questions': questions,
      'currentQuestionIndex': currentQuestionIndex,
      'currentQuestionStartTime':
          currentQuestionStartTime?.millisecondsSinceEpoch,
      'questionTimeLimit': questionTimeLimit,
      'participantAnswers': participantAnswersMap,
    };
  }

  // Static helper method to parse timestamps - handles both Firestore Timestamp and int
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value);
    }

    print('Warning: Unexpected timestamp type: ${value.runtimeType}');
    return null;
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
    String? subject,
    String? fileName,
    List<Map<String, dynamic>>? questions,
    int? currentQuestionIndex,
    DateTime? currentQuestionStartTime,
    int? questionTimeLimit,
    Map<String, List<int>>? participantAnswers,
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
      subject: subject ?? this.subject,
      fileName: fileName ?? this.fileName,
      questions: questions != null
          ? List.from(questions)
          : List.from(this.questions),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentQuestionStartTime:
          currentQuestionStartTime ?? this.currentQuestionStartTime,
      questionTimeLimit: questionTimeLimit ?? this.questionTimeLimit,
      participantAnswers: participantAnswers != null
          ? Map.from(participantAnswers)
          : Map.from(this.participantAnswers),
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
        other.quizName == quizName &&
        other.subject == subject &&
        other.fileName == fileName &&
        _listEquals(other.questions, questions) &&
        other.currentQuestionIndex == currentQuestionIndex &&
        other.currentQuestionStartTime == currentQuestionStartTime &&
        other.questionTimeLimit == questionTimeLimit &&
        _participantAnswersEquals(other.participantAnswers, participantAnswers);
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
      subject,
      fileName,
      Object.hashAll(questions),
      currentQuestionIndex,
      currentQuestionStartTime,
      questionTimeLimit,
      Object.hashAll(
        participantAnswers.entries.map(
          (e) => Object.hash(e.key, Object.hashAll(e.value)),
        ),
      ),
    );
  }

  @override
  String toString() {
    return 'QuizSessionModel(id: $id, groupId: $groupId, status: $status, participants: $participants, startedAt: $startedAt, quizName: $quizName, subject: $subject, fileName: $fileName, questions: ${questions.length}, currentQuestionIndex: $currentQuestionIndex)';
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
    return isWaiting && hasMinimumOnlinePlayers && hasQuestionsLoaded();
  }

  bool isReconnectionTimeoutExpired(String userId) {
    final participant = getParticipant(userId);
    if (participant?.disconnectedAt == null) return false;

    return DateTime.now().difference(participant!.disconnectedAt!) >
        const Duration(minutes: 1);
  }

  QuizParticipant? getParticipant(String userId) => participants[userId];

  // New quiz game helper methods
  Map<String, dynamic>? getCurrentQuestion() {
    if (!hasQuestionsLoaded() || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  bool hasQuestionsLoaded() {
    return questions.isNotEmpty;
  }

  bool isQuestionActive() {
    return currentQuestionStartTime != null &&
        getCurrentQuestion() != null &&
        !isQuestionTimeExpired();
  }

  bool isQuestionTimeExpired() {
    if (currentQuestionStartTime == null) return false;

    final elapsed = DateTime.now().difference(currentQuestionStartTime!);
    return elapsed.inSeconds >= questionTimeLimit;
  }

  Duration? getQuestionTimeRemaining() {
    if (currentQuestionStartTime == null) return null;

    final elapsed = DateTime.now().difference(currentQuestionStartTime!);
    final remaining = Duration(seconds: questionTimeLimit) - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;

  int get totalQuestions => questions.length;

  List<int> getParticipantAnswersForQuestion(String userId, int questionIndex) {
    final userAnswers = participantAnswers[userId];
    if (userAnswers == null || questionIndex >= userAnswers.length) {
      return [];
    }
    return [userAnswers[questionIndex]];
  }

  bool hasParticipantAnswered(String userId) {
    final userAnswers = participantAnswers[userId];
    if (userAnswers == null) return false;

    return userAnswers.length > currentQuestionIndex;
  }

  // Helper method for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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

  // Helper method for participant answers comparison
  bool _participantAnswersEquals(
    Map<String, List<int>>? a,
    Map<String, List<int>>? b,
  ) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_listEquals(a[key], b[key])) return false;
    }
    return true;
  }
}
