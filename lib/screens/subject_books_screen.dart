// Enhanced Books Screen
import 'package:flutter/material.dart';

class SubjectBooksScreen extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectBooksScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final books = _getBooksForSubject(subject['name'] as String);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('${subject['name']} Books'),
        backgroundColor: subject['color'] as Color,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: (subject['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: subject['color'] as Color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By ${book['author']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: book['available'] as bool
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                book['available'] as bool
                                    ? 'Available'
                                    : 'Coming Soon',
                                style: TextStyle(
                                  color: book['available'] as bool
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${book['pages']} pages',
                              style: TextStyle(
                                color: Colors.grey[500],
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
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getBooksForSubject(String subjectName) {
    final allBooks = {
      'Mathematics': [
        {
          'title': 'Advanced Mathematics Textbook',
          'author': 'Dr. Johnson Smith',
          'pages': 456,
          'available': true,
        },
        {
          'title': 'Calculus and Beyond',
          'author': 'Prof. Sarah Wilson',
          'pages': 523,
          'available': true,
        },
        {
          'title': 'Statistics Made Simple',
          'author': 'Michael Brown',
          'pages': 312,
          'available': false,
        },
      ],
      'Physics': [
        {
          'title': 'Fundamentals of Physics',
          'author': 'Dr. Einstein Jr.',
          'pages': 678,
          'available': true,
        },
        {
          'title': 'Quantum Mechanics Basics',
          'author': 'Prof. Marie Curie',
          'pages': 445,
          'available': true,
        },
      ],
      'Chemistry': [
        {
          'title': 'Organic Chemistry Essentials',
          'author': 'Dr. Watson Holmes',
          'pages': 567,
          'available': true,
        },
        {
          'title': 'Chemical Reactions Guide',
          'author': 'Prof. Ada Lovelace',
          'pages': 389,
          'available': false,
        },
      ],
    };

    return allBooks[subjectName] ?? [];
  }
}

// Notes Screen
class SubjectNotesScreen extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectNotesScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('${subject['name']} Notes'),
        backgroundColor: subject['color'] as Color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: subject['color'] as Color),
            const SizedBox(height: 16),
            Text(
              '${subject['name']} Notes',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Study notes and summaries will be available here'),
          ],
        ),
      ),
    );
  }
}
