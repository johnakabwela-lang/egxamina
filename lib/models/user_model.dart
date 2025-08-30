class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final int points;
  final int level;
  final String? currentGroup;
  final DateTime joinedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.points,
    required this.level,
    this.currentGroup,
    required this.joinedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String?,
      points: map['points'] as int,
      level: map['level'] as int,
      currentGroup: map['currentGroup'] as String?,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(map['joinedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'points': points,
      'level': level,
      'currentGroup': currentGroup,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    int? points,
    int? level,
    String? currentGroup,
    DateTime? joinedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      points: points ?? this.points,
      level: level ?? this.level,
      currentGroup: currentGroup ?? this.currentGroup,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatar == avatar &&
        other.points == points &&
        other.level == level &&
        other.currentGroup == currentGroup &&
        other.joinedAt == joinedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      avatar,
      points,
      level,
      currentGroup,
      joinedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, avatar: $avatar, points: $points, level: $level, currentGroup: $currentGroup, joinedAt: $joinedAt)';
  }
}
