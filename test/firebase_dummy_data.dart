import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ultsukulu/models/user_model.dart';
import 'package:ultsukulu/models/group_model.dart';
import 'package:ultsukulu/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;

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

      // Set up Realtime Database user presence
      await database.ref('users').child(uid).child('status').set({
        'state': 'offline',
        'lastSeen': ServerValue.timestamp,
        'deviceInfo': {
          'platform': 'Flutter',
          'lastActivity': ServerValue.timestamp,
        },
      });

      await database.ref('user_presence').child(uid).set(false);

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

      // Set up Realtime Database group activity
      await database.ref('group_activity').child(groupId).set({
        'lastActivity': ServerValue.timestamp,
        'activeMembers': {groupData['createdBy']: true},
      });

      // Initialize chat structure
      await database.ref('chats').child(groupId).set({
        'info': {
          'createdAt': ServerValue.timestamp,
          'createdBy': groupData['createdBy'],
        },
      });

      print('Created group: ${groupData['name']}');

      // Update the creator's currentGroup
      await firestore.collection('users').doc(groupData['createdBy']).update({
        'currentGroup': groupId,
      });
    } catch (e) {
      print('Error creating group ${groupData['name']}: $e');
    }
  }

  // Add some example chat messages
  for (var groupData in dummyGroups) {
    try {
      final chatRef = database
          .ref('chats')
          .child(groupData['name'].toLowerCase().replaceAll(' ', '_'));

      // Add welcome message
      await chatRef.child('messages').push().set({
        'userId': groupData['createdBy'],
        'content': 'Welcome to the ${groupData['name']}! 👋',
        'timestamp': ServerValue.timestamp,
        'type': 'text',
      });

      // Add sample study message
      await chatRef.child('messages').push().set({
        'userId': groupData['createdBy'],
        'content': 'Let\'s start our ${groupData['subject']} study session! 📚',
        'timestamp': ServerValue.timestamp,
        'type': 'text',
      });

      print('Added sample messages to group: ${groupData['name']}');
    } catch (e) {
      print('Error adding messages to group ${groupData['name']}: $e');
    }
  }

  print('Finished creating dummy data');
  exit(0);
}
