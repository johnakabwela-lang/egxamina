import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String createdBy;
  final List<String> members;
  final int memberCount;
  final int maxMembers;
  final int totalPoints;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.subject,
    this.description = '', // Default to empty string if not provided
    required this.createdBy,
    required this.members,
    required this.memberCount,
    this.maxMembers = 50, // Default max members if not specified
    required this.totalPoints,
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    // Handle different timestamp formats from Firestore
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      if (timestamp is DateTime) return timestamp;
      if (timestamp is Timestamp) return timestamp.toDate();
      return DateTime.now();
    }

    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      subject: map['subject'] as String,
      description: (map['description'] as String?) ?? '',
      createdBy: map['createdBy'] as String,
      members: List<String>.from(map['members'] as List),
      memberCount: map['memberCount'] as int,
      maxMembers:
          (map['maxMembers'] as int?) ?? 50, // Default to 50 if not in map
      totalPoints: map['totalPoints'] as int,
      createdAt: parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'description': description,
      'createdBy': createdBy,
      'members': members,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'totalPoints': totalPoints,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? subject,
    String? description,
    String? createdBy,
    List<String>? members,
    int? memberCount,
    int? maxMembers,
    int? totalPoints,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? List.from(this.members),
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method to check if group is full
  bool get isFull => memberCount >= maxMembers;

  // Helper method to get available spots
  int get availableSpots => maxMembers - memberCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.subject == subject &&
        other.description == description &&
        other.createdBy == createdBy &&
        _listEquals(other.members, members) &&
        other.memberCount == memberCount &&
        other.maxMembers == maxMembers &&
        other.totalPoints == totalPoints &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      subject,
      description,
      createdBy,
      Object.hashAll(members),
      memberCount,
      maxMembers,
      totalPoints,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, subject: $subject, description: $description, createdBy: $createdBy, members: $members, memberCount: $memberCount, maxMembers: $maxMembers, totalPoints: $totalPoints, createdAt: $createdAt)';
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
