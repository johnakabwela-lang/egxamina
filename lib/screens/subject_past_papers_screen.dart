import 'package:flutter/material.dart';
import 'package:ultsukulu/screens/home_screen.dart';

// New Subject-Specific Past Papers Screen
class SubjectPastPapersScreen extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectPastPapersScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Sample past papers data for the specific subject
    final pastPapers = _getPastPapersForSubject(subject['name'] as String);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('${subject['name']} Past Papers'),
        backgroundColor: subject['color'] as Color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with subject info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: subject['color'] as Color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    subject['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pastPapers.length} Papers Available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sorted by year (newest first)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Filter by:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterChip('All', true),
                const SizedBox(width: 8),
                _buildFilterChip('Final Exam', false),
                const SizedBox(width: 8),
                _buildFilterChip('Mock Exam', false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Past Papers List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pastPapers.length,
              itemBuilder: (context, index) {
                final paper = pastPapers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (subject['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: subject['color'] as Color,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      paper['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Year: ${paper['year']} • ${paper['type']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${paper['duration']} min',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.help_outline,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${paper['questions']} questions',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastPaperDetailScreen(
                          paper: {
                            ...paper,
                            'subject': subject['name'],
                            'color': subject['color'],
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? subject['color'] as Color : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPastPapersForSubject(String subjectName) {
    // Sample data - in a real app, this would come from a database
    final allPapers = {
      'Mathematics': [
        {
          'title': 'Mathematics Final Examination',
          'year': '2023',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 25,
        },
        {
          'title': 'Mathematics Mock Examination',
          'year': '2023',
          'type': 'Mock Exam',
          'duration': 150,
          'questions': 20,
        },
        {
          'title': 'Mathematics Final Examination',
          'year': '2022',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 25,
        },
        {
          'title': 'Mathematics Midterm Examination',
          'year': '2022',
          'type': 'Midterm',
          'duration': 120,
          'questions': 15,
        },
        {
          'title': 'Mathematics Final Examination',
          'year': '2021',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 24,
        },
      ],
      'Physics': [
        {
          'title': 'Physics Final Examination',
          'year': '2023',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 30,
        },
        {
          'title': 'Physics Mock Examination',
          'year': '2023',
          'type': 'Mock Exam',
          'duration': 150,
          'questions': 25,
        },
        {
          'title': 'Physics Final Examination',
          'year': '2022',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 28,
        },
      ],
      'Chemistry': [
        {
          'title': 'Chemistry Final Examination',
          'year': '2023',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 35,
        },
        {
          'title': 'Chemistry Final Examination',
          'year': '2022',
          'type': 'Final Exam',
          'duration': 180,
          'questions': 33,
        },
        {
          'title': 'Chemistry Midterm Examination',
          'year': '2022',
          'type': 'Midterm',
          'duration': 120,
          'questions': 20,
        },
      ],
    };

    return allPapers[subjectName] ?? [];
  }
}
