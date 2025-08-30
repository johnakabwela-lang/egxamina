import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ultsukulu/models/user_model.dart';
import '../lib/models/group_model.dart';
import '../lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // List of dummy users to create
  final List<Map<String, dynamic>> dummyUsers = [
    {
      'email': 'john.doe@example.com',
      'password': 'testpass123',
      'userData': {'name': 'John Doe', 'points': 100, 'level': 1},
    },
    {
      'email': 'jane.smith@example.com',
      'password': 'testpass123',
      'userData': {'name': 'Jane Smith', 'points': 150, 'level': 2},
    },
    {
      'email': 'bob.wilson@example.com',
      'password': 'testpass123',
      'userData': {'name': 'Bob Wilson', 'points': 75, 'level': 1},
    },
  ];

  // Create users and store their IDs
  List<String> userIds = [];

  for (var userData in dummyUsers) {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(
            email: userData['email'],
            password: userData['password'],
          );

      final String uid = userCredential.user!.uid;
      userIds.add(uid);

      // Create user document in Firestore
      final UserModel user = UserModel(
        id: uid,
        name: userData['userData']['name'],
        email: userData['email'],
        points: userData['userData']['points'],
        level: userData['userData']['level'],
        joinedAt: DateTime.now(),
      );

      await firestore.collection('users').doc(uid).set(user.toMap());
      print('Created user: ${userData['email']}');
    } catch (e) {
      print('Error creating user ${userData['email']}: $e');
    }
  }

  // List of dummy groups to create
  final List<Map<String, dynamic>> dummyGroups = [
    {
      'name': 'Chemistry Study Group',
      'subject': 'Chemistry',
      'createdBy': userIds[0], // John's group
    },
    {
      'name': 'Physics Masters',
      'subject': 'Physics',
      'createdBy': userIds[1], // Jane's group
    },
    {
      'name': 'Biology Research Team',
      'subject': 'Biology',
      'createdBy': userIds[2], // Bob's group
    },
  ];

  // Create groups
  for (var groupData in dummyGroups) {
    try {
      final String groupId = firestore.collection('groups').doc().id;

      final GroupModel group = GroupModel(
        id: groupId,
        name: groupData['name'],
        subject: groupData['subject'],
        createdBy: groupData['createdBy'],
        members: [groupData['createdBy']], // Initially only creator is a member
        memberCount: 1,
        totalPoints: 0,
        createdAt: DateTime.now(),
      );

      await firestore.collection('groups').doc(groupId).set(group.toMap());
      print('Created group: ${groupData['name']}');

      // Update the creator's currentGroup
      await firestore.collection('users').doc(groupData['createdBy']).update({
        'currentGroup': groupId,
      });
    } catch (e) {
      print('Error creating group ${groupData['name']}: $e');
    }
  }

  print('Finished creating dummy data');
  exit(0);
}
