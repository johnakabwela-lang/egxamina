import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Custom exceptions for user service
  static const String _userNotFoundError = 'User not found';
  static const String _updateFailedError = 'Failed to update user profile';
  static const String _pointsUpdateFailedError = 'Failed to update user points';
  static const String _leaderboardFetchFailedError =
      'Failed to fetch leaderboard';

  /// Get user profile as a stream for real-time updates
  static Stream<UserModel?> getUserProfileStream(String userId) {
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }

            try {
              final data = snapshot.data();
              if (data == null) return null;

              return UserModel.fromMap({'id': snapshot.id, ...data});
            } catch (e) {
              throw Exception('Failed to parse user data: ${e.toString()}');
            }
          });
    } catch (e) {
      throw Exception('Failed to get user profile stream: ${e.toString()}');
    }
  }

  /// Get user profile as a one-time fetch
  static Future<UserModel> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception(_userNotFoundError);
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('User data is null');
      }

      return UserModel.fromMap({'id': doc.id, ...data});
    } catch (e) {
      if (e.toString().contains(_userNotFoundError)) {
        rethrow;
      }
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Remove fields that shouldn't be updated directly
      final filteredUpdates = Map<String, dynamic>.from(updates);
      filteredUpdates.removeWhere(
        (key, value) => key == 'id' || key == 'joinedAt',
      );

      // Add timestamp for when profile was last updated
      filteredUpdates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(filteredUpdates);
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        throw Exception(_userNotFoundError);
      }
      throw Exception('$_updateFailedError: ${e.toString()}');
    }
  }

  /// Update specific user profile fields
  static Future<void> updateUserFields(
    String userId, {
    String? name,
    String? email,
    String? avatar,
    String? currentGroup,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (avatar != null) updates['avatar'] = avatar;
    if (currentGroup != null) updates['currentGroup'] = currentGroup;

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    await updateUserProfile(userId, updates);
  }

  /// Add points to user and potentially update level
  static Future<void> addPointsToUser(String userId, int pointsToAdd) async {
    if (pointsToAdd <= 0) {
      throw Exception('Points to add must be positive');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection(_usersCollection).doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception(_userNotFoundError);
        }

        final userData = userDoc.data()!;
        final currentPoints = userData['points'] as int? ?? 0;
        final currentLevel = userData['level'] as int? ?? 1;

        final newPoints = currentPoints + pointsToAdd;

        // Calculate new level (example: every 100 points = 1 level)
        final newLevel = (newPoints ~/ 100) + 1;

        final updates = {
          'points': newPoints,
          'level': newLevel > currentLevel ? newLevel : currentLevel,
          'lastPointsUpdate': FieldValue.serverTimestamp(),
        };

        transaction.update(userRef, updates);
      });
    } catch (e) {
      if (e.toString().contains(_userNotFoundError)) {
        rethrow;
      }
      throw Exception('$_pointsUpdateFailedError: ${e.toString()}');
    }
  }

  /// Get leaderboard of top users by points
  static Future<List<UserModel>> getUserLeaderboard({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('$_leaderboardFetchFailedError: ${e.toString()}');
    }
  }

  /// Get users by level
  static Future<List<UserModel>> getUsersByLevel(int level) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('level', isEqualTo: level)
          .orderBy('points', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch users by level: ${e.toString()}');
    }
  }

  /// Create new user profile
  static Future<UserModel> createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? avatar,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'avatar': avatar,
        'points': 0,
        'level': 1,
        'currentGroup': null,
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_usersCollection).doc(userId).set(userData);

      // Fetch the created user to return with server timestamp
      return await getUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Check if user exists
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: ${e.toString()}');
    }
  }

  /// Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: ${e.toString()}');
    }
  }

  /// Get multiple users by IDs
  static Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      // Firestore 'in' queries are limited to 10 items
      const batchSize = 10;
      final List<UserModel> allUsers = [];

      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final querySnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchUsers = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return UserModel.fromMap({'id': doc.id, ...data});
        }).toList();

        allUsers.addAll(batchUsers);
      }

      return allUsers;
    } catch (e) {
      throw Exception('Failed to fetch users by IDs: ${e.toString()}');
    }
  }
}
