import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ultsukulu/services/group_service.dart';

class GroupDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _groupsCollection = 'groups';

  /// Schedule group for deletion with a grace period
  static Future<void> scheduleGroupDeletion(
    String groupId,
    String currentOwnerId,
  ) async {
    try {
      final group = await GroupService.getGroupDetails(groupId);

      if (group.createdBy != currentOwnerId) {
        throw Exception('Only the current owner can delete the group');
      }

      // Set deletion schedule
      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'scheduledForDeletion': true,
        'deletionScheduledAt': FieldValue.serverTimestamp(),
        'deletionScheduledBy': currentOwnerId,
        'deletionDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      // Notify all members
      for (String memberId in group.members) {
        await _firestore
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .add({
              'type': 'GROUP_DELETION_SCHEDULED',
              'groupId': groupId,
              'groupName': group.name,
              'scheduledDeletionTime': Timestamp.fromDate(
                DateTime.now().add(const Duration(hours: 24)),
              ),
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            });
      }
    } catch (e) {
      throw Exception('Failed to schedule group deletion: ${e.toString()}');
    }
  }

  /// Cancel scheduled deletion
  static Future<void> cancelDeletion(
    String groupId,
    String currentOwnerId,
  ) async {
    try {
      final group = await GroupService.getGroupDetails(groupId);

      if (group.createdBy != currentOwnerId) {
        throw Exception('Only the current owner can cancel deletion');
      }

      await _firestore.collection(_groupsCollection).doc(groupId).update({
        'scheduledForDeletion': false,
        'deletionScheduledAt': null,
        'deletionScheduledBy': null,
        'deletionDate': null,
      });

      // Notify members
      for (String memberId in group.members) {
        await _firestore
            .collection('users')
            .doc(memberId)
            .collection('notifications')
            .add({
              'type': 'GROUP_DELETION_CANCELLED',
              'groupId': groupId,
              'groupName': group.name,
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            });
      }
    } catch (e) {
      throw Exception('Failed to cancel group deletion: ${e.toString()}');
    }
  }

  /// Immediately delete the group
  static Future<void> deleteGroupImmediately(
    String groupId,
    String currentOwnerId,
  ) async {
    try {
      final group = await GroupService.getGroupDetails(groupId);

      if (group.createdBy != currentOwnerId) {
        throw Exception('Only the current owner can delete the group');
      }

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection(_groupsCollection).doc(groupId);

        // Update all member references
        for (String memberId in group.members) {
          final userRef = _firestore.collection('users').doc(memberId);
          transaction.update(userRef, {
            'currentGroup': null,
            'leftGroupAt': FieldValue.serverTimestamp(),
            'ownedGroups': FieldValue.arrayRemove([groupId]),
          });
        }

        // Delete the group document
        transaction.delete(groupRef);
      });

      // Clean up Realtime Database data
      await Future.wait([
        _database.ref('group_activity').child(groupId).remove(),
        _database.ref('chats').child(groupId).remove(),
      ]);
    } catch (e) {
      throw Exception('Failed to delete group: ${e.toString()}');
    }
  }

  /// Check if user has permission to delete group
  static Future<bool> canDeleteGroup(String groupId, String userId) async {
    try {
      final group = await GroupService.getGroupDetails(groupId);
      return group.createdBy == userId;
    } catch (e) {
      return false;
    }
  }

  /// Get deletion status
  static Future<Map<String, dynamic>?> getDeletionStatus(String groupId) async {
    try {
      final doc = await _firestore
          .collection(_groupsCollection)
          .doc(groupId)
          .get();
      final data = doc.data();

      if (data == null || !data.containsKey('scheduledForDeletion')) {
        return null;
      }

      return {
        'scheduledForDeletion': data['scheduledForDeletion'],
        'deletionScheduledAt': data['deletionScheduledAt'],
        'deletionDate': data['deletionDate'],
      };
    } catch (e) {
      return null;
    }
  }
}
