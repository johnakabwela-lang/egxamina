class GroupModel {
  final String id;
  final String name;
  final String subject;
  final String createdBy;
  final List<String> members;
  final int memberCount;
  final int totalPoints;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.createdBy,
    required this.members,
    required this.memberCount,
    required this.totalPoints,
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      subject: map['subject'] as String,
      createdBy: map['createdBy'] as String,
      members: List<String>.from(map['members'] as List),
      memberCount: map['memberCount'] as int,
      totalPoints: map['totalPoints'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'createdBy': createdBy,
      'members': members,
      'memberCount': memberCount,
      'totalPoints': totalPoints,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? subject,
    String? createdBy,
    List<String>? members,
    int? memberCount,
    int? totalPoints,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? List.from(this.members),
      memberCount: memberCount ?? this.memberCount,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.subject == subject &&
        other.createdBy == createdBy &&
        _listEquals(other.members, members) &&
        other.memberCount == memberCount &&
        other.totalPoints == totalPoints &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      subject,
      createdBy,
      Object.hashAll(members),
      memberCount,
      totalPoints,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, subject: $subject, createdBy: $createdBy, members: $members, memberCount: $memberCount, totalPoints: $totalPoints, createdAt: $createdAt)';
  }

  // Helper method for list comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
