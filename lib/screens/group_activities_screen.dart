// Group Activities Screen
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ultsukulu/models/group_model.dart';
import 'package:ultsukulu/screens/social_screen.dart';
import 'package:ultsukulu/services/group_service.dart';
import 'package:ultsukulu/services/quiz_service.dart';
import 'package:ultsukulu/widgets/play_with_group_dialog.dart';

class GroupActivitiesScreen extends StatelessWidget {
  final GroupModel group;
  final QuizService _quizService = QuizService();

  GroupActivitiesScreen({super.key, required this.group});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: _getGroupColor(group.subject),
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
                          () => _showQuizSetupDialog(context),
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
    final Color color = _getGroupColor(group.subject);
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
              _getGroupIcon(group.subject),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            group.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${group.memberCount} members • ${group.subject}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showQuizSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PlayWithGroupDialog(
        subject: group.subject,
        fileName: '${group.subject.toLowerCase()}_questions.json',
        groupId: group.id, // Pass the group ID
      ),
    );
  }

  Future<void> _showLeaveGroupDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // TODO: Replace with actual user ID from auth
                await GroupService.leaveGroup(group.id, "current_user_id");
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
                        content: Text('Left ${group.name}'),
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
}
