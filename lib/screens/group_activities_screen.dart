// Group Activities Screen
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ultsukulu/models/group_model.dart';
import 'package:ultsukulu/models/quiz_session_model.dart';
import 'package:ultsukulu/screens/social_screen.dart';
import 'package:ultsukulu/screens/multiplayer_quiz_screen.dart';
import 'package:ultsukulu/services/auth_service.dart';
import 'package:ultsukulu/services/group_service.dart';
import 'package:ultsukulu/services/group_deletion_service.dart';
import 'package:ultsukulu/services/quiz_service.dart';

class GroupActivitiesScreen extends StatefulWidget {
  final GroupModel group;

  const GroupActivitiesScreen({super.key, required this.group});

  @override
  State<GroupActivitiesScreen> createState() => _GroupActivitiesScreenState();
}

class _GroupActivitiesScreenState extends State<GroupActivitiesScreen> {
  final QuizService _quizService = QuizService();
  Map<String, dynamic>? _deletionStatus;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkDeletionStatus();
    _checkOwnership();
  }

  Future<void> _checkDeletionStatus() async {
    try {
      final status = await GroupDeletionService.getDeletionStatus(
        widget.group.id,
      );
      setState(() {
        _deletionStatus = status;
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _checkOwnership() async {
    final user = AuthService.currentUser;
    if (user != null) {
      final canDelete = await GroupDeletionService.canDeleteGroup(
        widget.group.id,
        user.uid,
      );
      setState(() {
        _isOwner = canDelete;
      });
    }
  }

  void _showQuizOptions(BuildContext context) async {
    if (!AuthService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to participate in group quizzes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get active sessions for this group
    final Stream<List<QuizSessionModel>> activeSessionsStream = _quizService
        .getActiveGroupSessions(widget.group.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<List<QuizSessionModel>>(
          stream: activeSessionsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final activeSessions = snapshot.data!;
            final waitingSessions = activeSessions
                .where((s) => s.isWaiting)
                .toList();

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Group Quiz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _createNewQuizSession(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getGroupColor(widget.group.subject),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  if (waitingSessions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Available Sessions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...waitingSessions.map((session) {
                      final hostName = session.participants.values
                          .firstWhere(
                            (p) => p.userId == session.participants.keys.first,
                          )
                          .userName;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getGroupColor(
                            widget.group.subject,
                          ).withOpacity(0.2),
                          child: const Icon(Icons.quiz),
                        ),
                        title: Text(session.quizName),
                        subtitle: Text('Host: $hostName'),
                        trailing: ElevatedButton(
                          onPressed: () => _joinQuizSession(context, session),
                          child: const Text('Join'),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createNewQuizSession(BuildContext context) async {
    try {
      final user = AuthService.currentUser!;
      final profile = await AuthService.getCurrentUserProfile();

      final session = await _quizService.startMultiplayerSession(
        groupId: widget.group.id,
        quizName: '${widget.group.subject} Quiz',
        hostUserId: user.uid,
        hostUserName: profile?.name ?? user.email ?? 'Anonymous User',
      );

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerQuizScreen(
              session: session,
              currentUserId: user.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quiz session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinQuizSession(
    BuildContext context,
    QuizSessionModel session,
  ) async {
    try {
      final user = AuthService.currentUser!;
      final profile = await AuthService.getCurrentUserProfile();

      await _quizService.joinSession(
        sessionId: session.id,
        userId: user.uid,
        userName: profile?.name ?? user.email ?? 'Anonymous User',
      );

      if (context.mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplayerQuizScreen(
              session: session,
              currentUserId: user.uid,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining quiz session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDeletionWarningBanner() {
    if (_deletionStatus == null ||
        _deletionStatus!['scheduledForDeletion'] != true) {
      return const SizedBox.shrink();
    }

    final deletionDate = _deletionStatus!['deletionDate'];
    final remainingTime = deletionDate != null
        ? deletionDate.toDate().difference(DateTime.now())
        : Duration.zero;

    if (remainingTime.isNegative) {
      return const SizedBox.shrink();
    }

    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Scheduled for Deletion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Time remaining: ${hours}h ${minutes}m',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          ),
          if (_isOwner)
            TextButton(onPressed: _cancelDeletion, child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _cancelDeletion() async {
    try {
      final user = AuthService.currentUser!;
      await GroupDeletionService.cancelDeletion(widget.group.id, user.uid);

      await _checkDeletionStatus(); // Refresh status

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deletion cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel deletion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: _getGroupColor(widget.group.subject),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showGroupOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group Header
          _buildGroupHeader(),

          // Deletion Warning Banner
          _buildDeletionWarningBanner(),

          const SizedBox(height: 20),
          // Activity Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Activities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Activity Cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActivityCard(
                          'Group Chat',
                          'Discuss and share ideas',
                          Icons.chat,
                          Colors.blue,
                          () => _showComingSoon(context, 'Group Chat'),
                        ),
                        _buildActivityCard(
                          'Study Sessions',
                          'Schedule group study times',
                          Icons.schedule,
                          Colors.green,
                          () => _showComingSoon(context, 'Study Sessions'),
                        ),
                        _buildActivityCard(
                          'Share Resources',
                          'Upload and share materials',
                          Icons.folder_shared,
                          Colors.orange,
                          () => _showComingSoon(context, 'Share Resources'),
                        ),
                        _buildActivityCard(
                          'Group Quiz',
                          'Test knowledge together',
                          Icons.quiz,
                          Colors.purple,
                          () => _showQuizOptions(context),
                        ),
                        _buildActivityCard(
                          'Members',
                          'View group members',
                          Icons.people,
                          Colors.teal,
                          () => _showComingSoon(context, 'Members'),
                        ),
                        _buildActivityCard(
                          'Progress',
                          'Track group progress',
                          Icons.trending_up,
                          Colors.indigo,
                          () => _showComingSoon(context, 'Progress'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Group Settings'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Group Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Notifications');
              },
            ),

            // Show deletion options for group owners
            if (_isOwner) ...[
              const Divider(),
              if (_deletionStatus?['scheduledForDeletion'] == true)
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.orange),
                  title: const Text(
                    'Cancel Deletion',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _cancelDeletion();
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(
                    Icons.schedule_send,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'Schedule Deletion',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showScheduleDeletionDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete Immediately',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteImmediatelyDialog(context);
                  },
                ),
              ],
            ] else
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Leave Group',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLeaveGroupDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleDeletionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Group Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will schedule "${widget.group.name}" for deletion in 24 hours.',
            ),
            const SizedBox(height: 8),
            const Text(
              'All members will be notified and you can cancel anytime before the deadline.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = AuthService.currentUser!;
                await GroupDeletionService.scheduleGroupDeletion(
                  widget.group.id,
                  user.uid,
                );

                await _checkDeletionStatus(); // Refresh status

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deletion scheduled for 24 hours'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to schedule deletion: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteImmediatelyDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group Immediately'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${widget.group.name}"?',
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone and all group data will be lost.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = AuthService.currentUser!;
                await GroupDeletionService.deleteGroupImmediately(
                  widget.group.id,
                  user.uid,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to social screen

                  if (context.mounted) {
                    final socialScreen = context
                        .findAncestorStateOfType<SocialScreenState>();
                    if (socialScreen != null) {
                      await socialScreen.loadUserGroups();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.group.name} has been deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete group: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLeaveGroupDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = AuthService.currentUser!;
                await GroupService.leaveGroup(widget.group.id, user.uid);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to social screen
                  if (context.mounted) {
                    final socialScreen = context
                        .findAncestorStateOfType<SocialScreenState>();
                    if (socialScreen != null) {
                      await socialScreen.loadUserGroups();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Left ${widget.group.name}'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to leave group: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return const Color(0xFF4285F4);
      case 'physics':
        return const Color(0xFFFF6B6B);
      case 'biology':
        return const Color(0xFF45B7D1);
      case 'chemistry':
        return const Color(0xFF4ECDC4);
      case 'english':
        return const Color(0xFFF39C12);
      case 'history':
        return const Color(0xFF8E44AD);
      default:
        return const Color(0xFF58CC02);
    }
  }

  IconData _getGroupIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Icons.calculate;
      case 'physics':
        return Icons.science;
      case 'biology':
        return Icons.eco;
      case 'chemistry':
        return Icons.biotech;
      case 'english':
        return Icons.menu_book;
      case 'history':
        return Icons.history_edu;
      default:
        return Icons.school;
    }
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 25,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    final Color color = _getGroupColor(widget.group.subject);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getGroupIcon(widget.group.subject),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.group.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.group.memberCount} members • ${widget.group.subject}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
