import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  final _subjects = [
    'All',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
  ];

  String? _selectedSubject;
  bool _isLoading = false;
  List<GroupModel> _groups = [];
  List<GroupModel> _filteredGroups = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await GroupService.getAllGroups(
        subject: _selectedSubject == 'All' ? null : _selectedSubject,
        onlyJoinable: true,
      );

      setState(() {
        _groups = groups;
        _filteredGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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

  void _filterGroups(String query) {
    setState(() {
      _filteredGroups = _groups.where((group) {
        final matchesSearch =
            group.name.toLowerCase().contains(query.toLowerCase()) ||
            group.subject.toLowerCase().contains(query.toLowerCase());
        final matchesSubject =
            _selectedSubject == null ||
            _selectedSubject == 'All' ||
            group.subject == _selectedSubject;

        return matchesSearch && matchesSubject;
      }).toList();
    });
  }

  Future<void> _joinGroup(GroupModel group) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to join a group'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Study Group'),
        content: Text('Are you sure you want to join "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await GroupService.joinGroup(group.id, userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully joined ${group.name}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadGroups(); // Refresh the list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to join group: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Groups Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final isFull = group.memberCount >= 50; // Using default max members of 50
    final color = _getGroupColor(group.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              alpha: 13,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getGroupIcon(group.subject),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      group.subject,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'FULL',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Group description
          Text(
            'A study group for ${group.subject}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberCount}/50 members',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isFull ? null : () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isFull ? 'Full' : 'Join',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Join Study Group'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header (matching JoinGroupScreen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.search, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Find Study Groups',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Discover and join study groups',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search and Filter (matching JoinGroupScreen)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search groups...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterGroups,
                ),
                const SizedBox(height: 12),

                // Subject Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final isSelected = _selectedSubject == subject;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSubject = selected ? subject : null;
                            });
                            _filterGroups(_searchController.text);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFFF6B6B).withValues(
                            red: 255,
                            green: 107,
                            blue: 107,
                            alpha: 25,
                          ),
                          checkmarkColor: const Color(0xFFFF6B6B),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF6B6B)
                                : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Groups List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredGroups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredGroups[index];
                      return _buildGroupCard(group);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
