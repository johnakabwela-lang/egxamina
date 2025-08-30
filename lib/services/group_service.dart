import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _groupsCollection = 'groups';

  // Custom exceptions for group service
  static const String _groupNotFoundError = 'Group not found';
  static const String _createGroupFailedError = 'Failed to create group';
  static const String _joinGroupFailedError = 'Failed to join group';
  static const String _leaveGroupFailedError = 'Failed to leave group';
  static const String _fetchGroupsFailedError = 'Failed to fetch groups';
  static const String _userAlreadyInGroupError =
      'User is already in this group';
  static const String _userNotInGroupError = 'User is not in this group';
  static const String _groupFullError = 'Group has reached maximum capacity';

  /// Create a new study group
  static Future<GroupModel> createGroup({
    required String name,
    required String subject,
    required String createdBy,
    int maxMembers = 50,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty) {
        throw Exception('Group name cannot be empty');
      }
      if (subject.trim().isEmpty) {
        throw Exception('Subject cannot be empty');
      }

      final groupData = {
        'name': name.trim(),
        'subject': subject.trim(),
        'createdBy': createdBy,
        'members': [createdBy], // Creator is automatically a member
        'memberCount': 1,
        'maxMembers': maxMembers,
        'totalPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_groupsCollection)
          .add(groupData);

      // Update user's currentGroup field
      await UserService.updateUserFields(createdBy, currentGroup: docRef.id);

      // Fetch the created group to return with server timestamp
      return await getGroupDetails(docRef.id);
    } catch (e) {
      if (e.toString().contains('Group name cannot be empty') ||
          e.toString().contains('Subject cannot be empty')) {
        rethrow;
      }
      throw Exception('$_createGroupFailedError: ${e.toString()}');
    }
  }

  /// Join an existing group
  static Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection(_groupsCollection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception(_groupNotFoundError);
        }

        final groupData = groupDoc.data()!;
        final members = List<String>.from(groupData['members'] ?? []);
        final maxMembers = groupData['maxMembers'] as int? ?? 50;

        // Check if user is already in the group
        if (members.contains(userId)) {
          throw Exception(_userAlreadyInGroupError);
        }

        // Check if group is full
        if (members.length >= maxMembers) {
          throw Exception(_groupFullError);
        }

        // Add user to group
        members.add(userId);

        final updates = {
          'members': members,
          'memberCount': members.length,
          'lastActivity': FieldValue.serverTimestamp(),
        };

        transaction.update(groupRef, updates);

        // Update user's currentGroup field
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'currentGroup': groupId,
          'joinedGroupAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e.toString().contains(_groupNotFoundError) ||
          e.toString().contains(_userAlreadyInGroupError) ||
          e.toString().contains(_groupFullError)) {
        rethrow;
      }
      throw Exception('$_joinGroupFailedError: ${e.toString()}');
    }
  }

  /// Leave a group
  static Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection(_groupsCollection).doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception(_groupNotFoundError);
        }

        final groupData = groupDoc.data()!;
        final members = List<String>.from(groupData['members'] ?? []);
        final createdBy = groupData['createdBy'] as String;

        // Check if user is in the group
        if (!members.contains(userId)) {
          throw Exception(_userNotInGroupError);
        }

        // Remove user from group
        members.remove(userId);

        // If the creator is leaving and there are other members, transfer ownership
        String newCreatedBy = createdBy;
        if (createdBy == userId && members.isNotEmpty) {
          newCreatedBy = members.first; // Transfer to first remaining member
        }

        final updates = {
          'members': members,
          'memberCount': members.length,
          'createdBy': newCreatedBy,
          'lastActivity': FieldValue.serverTimestamp(),
        };

        // If no members left, delete the group
        if (members.isEmpty) {
          transaction.delete(groupRef);
        } else {
          transaction.update(groupRef, updates);
        }

        // Update user's currentGroup field
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'currentGroup': null,
          'leftGroupAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e.toString().contains(_groupNotFoundError) ||
          e.toString().contains(_userNotInGroupError)) {
        rethrow;
      }
      throw Exception('$_leaveGroupFailedError: ${e.toString()}');
    }
  }

  /// Get all available groups
  static Future<List<GroupModel>> getAllGroups({
    int limit = 20,
    String? subject,
    bool onlyJoinable = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_groupsCollection)
          .orderBy('lastActivity', descending: true);

      // Filter by subject if provided
      if (subject != null && subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
      }

      // Limit results
      query = query.limit(limit);

      final querySnapshot = await query.get();

      List<GroupModel> groups = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GroupModel.fromMap({'id': doc.id, ...data});
      }).toList();

      // Filter only joinable groups if requested
      if (onlyJoinable) {
        groups = groups.where((group) {
          final maxMembers = (group as dynamic).maxMembers ?? 50;
          return group.memberCount < maxMembers;
        }).toList();
      }

      return groups;
    } catch (e) {
      throw Exception('$_fetchGroupsFailedError: ${e.toString()}');
    }
  }

  /// Get groups by subject
  static Future<List<GroupModel>> getGroupsBySubject(String subject) async {
    return getAllGroups(subject: subject, limit: 50);
  }

  /// Search groups by name
  static Future<List<GroupModel>> searchGroupsByName(String searchTerm) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or similar
      final querySnapshot = await _firestore
          .collection(_groupsCollection)
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return GroupModel.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('Failed to search groups: ${e.toString()}');
    }
  }

  /// Get group members as UserModel objects
  static Future<List<UserModel>> getGroupMembers(String groupId) async {
    try {
      final groupDoc = await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception(_groupNotFoundError);
      }

      final groupData = groupDoc.data()!;
      final memberIds = List<String>.from(groupData['members'] ?? []);

      if (memberIds.isEmpty) {
        return [];
      }

      // Use UserService to get member details
      return await UserService.getUsersByIds(memberIds);
    } catch (e) {
      if (e.toString().contains(_groupNotFoundError)) {
        rethrow;
      }
      throw Exception('Failed to fetch group members: ${e.toString()}');
    }
  }

  /// Get group details as a stream for real-time updates
  static Stream<GroupModel?> getGroupDetailsStream(String groupId) {
    try {
      return _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }

            try {
              final data = snapshot.data();
              if (data == null) return null;

              return GroupModel.fromMap({'id': snapshot.id, ...data});
            } catch (e) {
              throw Exception('Failed to parse group data: ${e.toString()}');
            }
          });
    } catch (e) {
      throw Exception('Failed to get group details stream: ${e.toString()}');
    }
  }

  /// Get group details as a one-time fetch
  static Future<GroupModel> getGroupDetails(String groupId) async {
    try {
      final doc = await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .get();

      if (!doc.exists) {
        throw Exception(_groupNotFoundError);
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Group data is null');
      }

      return GroupModel.fromMap({'id': doc.id, ...data});
    } catch (e) {
      if (e.toString().contains(_groupNotFoundError)) {
        rethrow;
      }
      throw Exception('Failed to fetch group details: ${e.toString()}');
    }
  }

  /// Update group details (only by creator or admin)
  static Future<void> updateGroupDetails(
    String groupId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final group = await getGroupDetails(groupId);

      // Check if user is the creator
      if (group.createdBy != userId) {
        throw Exception('Only group creator can update group details');
      }

      // Remove fields that shouldn't be updated directly
      final filteredUpdates = Map<String, dynamic>.from(updates);
      filteredUpdates.removeWhere(
        (key, value) => [
          'id',
          'createdBy',
          'members',
          'memberCount',
          'createdAt',
        ].contains(key),
      );

      // Add timestamp for when group was last updated
      filteredUpdates['updatedAt'] = FieldValue.serverTimestamp();
      filteredUpdates['lastActivity'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .update(filteredUpdates);
    } catch (e) {
      throw Exception('Failed to update group details: ${e.toString()}');
    }
  }

  /// Add points to group's total points
  static Future<void> addPointsToGroup(String groupId, int points) async {
    try {
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'totalPoints': FieldValue.increment(points),
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add points to group: ${e.toString()}');
    }
  }

  /// Get all groups a user is a member of
  static Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_groupsCollection)
          .where('members', arrayContains: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': data['name'] as String, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user groups: ${e.toString()}');
    }
  }

  /// Get user's current group
  static Future<GroupModel?> getUserCurrentGroup(String userId) async {
    try {
      final user = await UserService.getUserProfile(userId);

      if (user.currentGroup == null) {
        return null;
      }

      return await getGroupDetails(user.currentGroup!);
    } catch (e) {
      if (e.toString().contains(_groupNotFoundError) ||
          e.toString().contains('User not found')) {
        return null;
      }
      throw Exception('Failed to get user\'s current group: ${e.toString()}');
    }
  }

  /// Check if user is member of group
  static Future<bool> isUserMemberOfGroup(String groupId, String userId) async {
    try {
      final group = await getGroupDetails(groupId);
      return group.members.contains(userId);
    } catch (e) {
      return false;
    }
  }
}
