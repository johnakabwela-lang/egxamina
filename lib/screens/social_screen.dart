import 'package:flutter/material.dart';

// Main Social Screen
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

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
                const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 48,
                ),
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
                    color: Colors.white.withOpacity(0.9),
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
                              builder: (context) => const JoinGroupScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // My Groups Section
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
              color: Colors.black.withOpacity(0.1),
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
                color: color.withOpacity(0.1),
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
    // Sample groups data - replace with actual data from your backend
    final myGroups = [
      {
        'id': '1',
        'name': 'Mathematics Study Circle',
        'subject': 'Mathematics',
        'members': 8,
        'color': const Color(0xFF4285F4),
        'icon': Icons.calculate,
        'lastActivity': '2 hours ago',
      },
      {
        'id': '2',
        'name': 'Physics Lab Group',
        'subject': 'Physics',
        'members': 5,
        'color': const Color(0xFFFF6B6B),
        'icon': Icons.science,
        'lastActivity': '1 day ago',
      },
      {
        'id': '3',
        'name': 'Biology Research Team',
        'subject': 'Biology',
        'members': 12,
        'color': const Color(0xFF45B7D1),
        'icon': Icons.eco,
        'lastActivity': '3 hours ago',
      },
    ];

    if (myGroups.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: myGroups.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupActivitiesScreen(group: group),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                        color: (group['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        group['icon'] as IconData,
                        color: group['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'] as String,
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
                                '${group['members']} members',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                group['lastActivity'] as String,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
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
        }).toList(),
      ),
    );
  }
}

// Create Study Group Screen
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubject;
  bool _isPrivate = false;

  final subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Create Study Group'),
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Your Study Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Set up a collaborative learning space',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Group Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Group Name
                          TextFormField(
                            controller: _groupNameController,
                            decoration: InputDecoration(
                              labelText: 'Group Name',
                              hintText: 'e.g., Advanced Mathematics Study Circle',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.group),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a group name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Subject Selection
                          DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.school),
                            ),
                            items: subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject,
                                child: Text(subject),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubject = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a subject';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Describe what your group will focus on...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Privacy Setting
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isPrivate ? Icons.lock : Icons.public,
                                  color: _isPrivate ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPrivate ? 'Private Group' : 'Public Group',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _isPrivate
                                            ? 'Only invited members can join'
                                            : 'Anyone can find and join',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isPrivate,
                                  onChanged: (value) {
                                    setState(() {
                                      _isPrivate = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Study Group',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement group creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study group created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Join Study Group Screen
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _searchController = TextEditingController();
  String? _selectedSubject;
  List<Map<String, dynamic>> _filteredGroups = [];

  final subjects = ['All', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'History'];

  // Sample available groups - replace with actual data from your backend
  final availableGroups = [
    {
      'id': '4',
      'name': 'Chemistry Exam Prep',
      'subject': 'Chemistry',
      'members': 15,
      'maxMembers': 20,
      'color': const Color(0xFF4ECDC4),
      'icon': Icons.biotech,
      'description': 'Preparing for upcoming chemistry finals together',
      'isPrivate': false,
    },
    {
      'id': '5',
      'name': 'English Literature Circle',
      'subject': 'English',
      'members': 8,
      'maxMembers': 12,
      'color': const Color(0xFFF39C12),
      'icon': Icons.menu_book,
      'description': 'Analyzing and discussing classic literature',
      'isPrivate': false,
    },
    {
      'id': '6',
      'name': 'Advanced Physics',
      'subject': 'Physics',
      'members': 6,
      'maxMembers': 10,
      'color': const Color(0xFFFF6B6B),
      'icon': Icons.science,
      'description': 'Tackling complex physics problems together',
      'isPrivate': false,
    },
    {
      'id': '7',
      'name': 'History Research Group',
      'subject': 'History',
      'members': 10,
      'maxMembers': 15,
      'color': const Color(0xFF8E44AD),
      'icon': Icons.history_edu,
      'description': 'Collaborative historical research and discussion',
      'isPrivate': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(availableGroups);
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
          // Header
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
                const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 48,
                ),
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

          // Search and Filter
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
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
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
                          selectedColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                          checkmarkColor: const Color(0xFFFF6B6B),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFFF6B6B) : Colors.black87,
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
            child: _filteredGroups.isEmpty
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final isFull = group['members'] >= group['maxMembers'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: (group['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  group['icon'] as IconData,
                  color: group['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group['subject'] as String,
                      style: TextStyle(
                        color: group['color'] as Color,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(
            group['description'] as String,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
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
                    '${group['members']}/${group['maxMembers']} members',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isFull ? null : () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: group['color'] as Color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  void _filterGroups(String query) {
    setState(() {
      _filteredGroups = availableGroups.where((group) {
        final matchesSearch = group['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            group['description'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesSubject = _selectedSubject == null || 
            _selectedSubject == 'All' || 
            group['subject'] == _selectedSubject;
        
        return matchesSearch && matchesSubject;
      }).toList();
    });
  }

  void _joinGroup(Map<String, dynamic> group) {
    // TODO: Implement join group logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Study Group'),
        content: Text('Are you sure you want to join "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully joined ${group['name']}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Join'),
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

// Group Activities Screen
class GroupActivitiesScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupActivitiesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(group['name']),
        backgroundColor: group['color'] as Color,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: group['color'] as Color,
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
                    group['icon'] as IconData,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  group['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group['members']} members • ${group['subject']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

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
              color: Colors.black.withOpacity(0.1),
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              title: const Text('Leave Group', style: TextStyle(color: Colors.red)),
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

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to social screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Left ${group['name']}'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
