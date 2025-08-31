import 'package:flutter/material.dart';
import 'package:ultsukulu/screens/create_group_screen.dart';
import 'package:ultsukulu/screens/groups_list_screen.dart';
import '../services/group_service.dart';
import '../models/group_model.dart';
import 'package:ultsukulu/services/auth_service.dart';

// Main Social Screen
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  Stream<List<GroupModel>>? _groupsStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGroupsStream();
    _loadUserGroups();
  }

  void _initGroupsStream() {
    final userId = AuthService.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _groupsStream = GroupService.getUserGroupsStream(userId);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      // Handle not authenticated case
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to view your groups'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _loadUserGroups() async {
    try {
      setState(() => _isLoading = true);
      final userId = AuthService.currentUser?.uid;
      if (userId != null) {
        await GroupService.getAllGroups(onlyJoinable: false);
        setState(() {
          // Update groups state
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: ${e.toString()}'),
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
        title: const Text('Study Groups'),
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF58CC02),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Connect & Learn Together',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Join study groups and collaborate with peers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildActionCard(
                          context,
                          'Create Study Group',
                          'Start your own study group and invite others',
                          Icons.group_add,
                          const Color(0xFF4285F4),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateGroupScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          context,
                          'Join Study Group',
                          'Find and join existing study groups',
                          Icons.search,
                          const Color(0xFFFF6B6B),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GroupsListScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // My Groups Section area
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'My Study Groups',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Group Cards
                  _buildMyGroupsList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<GroupModel>>(
      stream: _groupsStream,
      builder:
          (BuildContext context, AsyncSnapshot<List<GroupModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final groups = snapshot.data ?? [];

            if (groups.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Study Groups Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create or join a study group to get started',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final color = _getGroupColor(group.subject);
                  final icon = _getGroupIcon(group.subject);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupActivitiesScreen(group: group),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.memberCount} members',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Active',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
    );
  }
}

// Group Activities Screen
class GroupActivitiesScreen extends StatelessWidget {
  final GroupModel group;

  const GroupActivitiesScreen({super.key, required this.group});

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
                          () => _showComingSoon(context, 'Group Quiz'),
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
                        .findAncestorStateOfType<_SocialScreenState>();
                    if (socialScreen != null) {
                      await socialScreen._loadUserGroups();
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
