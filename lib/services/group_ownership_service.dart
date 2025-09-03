import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_service.dart';

class GroupOwnershipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _groupsCollection = 'groups';

  /// Transfer group ownership to another member
  static Future<void> transferOwnership(
    String groupId,
    String currentOwnerId,
    String newOwnerId,
  ) async {
    try {
      // Verify both users exist in the group
      final group = await GroupService.getGroupDetails(groupId);

      if (group.createdBy != currentOwnerId) {
        throw Exception('Only the current owner can transfer ownership');
      }

      if (!group.members.contains(newOwnerId)) {
        throw Exception('New owner must be a member of the group');
      }

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection(_groupsCollection).doc(groupId);

        // Update group ownership
        transaction.update(groupRef, {
          'createdBy': newOwnerId,
          'lastActivity': FieldValue.serverTimestamp(),
          'ownershipTransferredAt': FieldValue.serverTimestamp(),
          'previousOwner': currentOwnerId,
        });

        // Update user documents to reflect the change
        final currentOwnerRef = _firestore
            .collection('users')
            .doc(currentOwnerId);
        final newOwnerRef = _firestore.collection('users').doc(newOwnerId);

        transaction.update(currentOwnerRef, {
          'ownedGroups': FieldValue.arrayRemove([groupId]),
        });

        transaction.update(newOwnerRef, {
          'ownedGroups': FieldValue.arrayUnion([groupId]),
        });
      });
    } catch (e) {
      throw Exception('Failed to transfer group ownership: ${e.toString()}');
    }
  }

  /// Check if a user can be promoted to owner
  static Future<bool> canBePromotedToOwner(
    String groupId,
    String userId,
  ) async {
    try {
      final group = await GroupService.getGroupDetails(groupId);
      return group.members.contains(userId) && group.createdBy != userId;
    } catch (e) {
      return false;
    }
  }
}
