import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Note model
class Note {
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String subject;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.subject = 'General',
  });

  // Convert Note to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subject': subject,
    };
  }

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      subject: json['subject'] ?? 'General',
    );
  }
}

// Main Notepad Screen
class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  List<Note> notes = [];
  String searchQuery = '';
  String selectedSubject = 'All';
  final List<String> subjects = ['All', 'General', 'Work', 'Personal', 'Ideas', 'School'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Load notes from storage
  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notes') ?? [];
      
      setState(() {
        notes = notesJson.map((noteStr) {
          final noteData = json.decode(noteStr);
          return Note.fromJson(noteData);
        }).toList();
        isLoading = false;
      });

      // If no notes exist, create sample notes
      if (notes.isEmpty) {
        _createSampleNotes();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load notes');
    }
  }

  // Save notes to storage
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((note) => json.encode(note.toJson())).toList();
      await prefs.setStringList('notes', notesJson);
    } catch (e) {
      _showErrorSnackBar('Failed to save notes');
    }
  }

  void _createSampleNotes() {
    notes = [
      Note(
        id: '1',
        title: 'Welcome to Notepad',
        content: 'This is your first note! You can edit, delete, or create new notes. All notes are automatically saved.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        subject: 'General',
      ),
      Note(
        id: '2',
        title: 'Meeting Notes',
        content: 'Discuss project timeline\n- Phase 1: Research\n- Phase 2: Development\n- Phase 3: Testing',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        subject: 'Work',
      ),
    ];
    _saveNotes();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Note> get filteredNotes {
    return notes.where((note) {
      final matchesSearch = note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesSubject = selectedSubject == 'All' || note.subject == selectedSubject;
      return matchesSearch && matchesSubject;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _createNewNote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          onSave: (title, content, subject) async {
            final newNote = Note(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              subject: subject,
            );
            
            setState(() {
              notes.add(newNote);
            });
            
            await _saveNotes();
          },
          subjects: subjects.where((s) => s != 'All').toList(),
        ),
      ),
    );
  }

  void _editNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (title, content, subject) async {
            setState(() {
              note.title = title;
              note.content = content;
              note.subject = subject;
              note.updatedAt = DateTime.now();
            });
            
            await _saveNotes();
          },
          subjects: subjects.where((s) => s != 'All').toList(),
        ),
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                notes.remove(note);
              });
              await _saveNotes();
              if (mounted) Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        backgroundColor: const Color(0xFF32CD32),
        foregroundColor: Colors.white,
        title: const Text('Smart Notepad'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(notes: notes),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final isSelected = selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedSubject = subject;
                      });
                    },
                    selectedColor: const Color(0xFF32CD32).withOpacity(0.3),
                    checkmarkColor: const Color(0xFF32CD32),
                  ),
                );
              },
            ),
          ),
          // Notes list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF32CD32),
                    ),
                  )
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'No notes found'
                                  : 'No notes yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty
                                  ? 'Try adjusting your search'
                                  : 'Tap + to create your first note',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF32CD32).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      note.subject,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF32CD32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(note.updatedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _editNote(note),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editNote(note);
                              } else if (value == 'delete') {
                                _deleteNote(note);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        backgroundColor: const Color(0xFF32CD32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Note Editor Screen
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content, String subject) onSave;
  final List<String> subjects;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.onSave,
    required this.subjects,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedSubject;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedSubject = widget.note?.subject ?? 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        _titleController.text.trim(),
        _contentController.text.trim(),
        _selectedSubject,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            backgroundColor: Color(0xFF32CD32),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF32CD32),
        foregroundColor: Colors.white,
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Subject selector
            Row(
              children: [
                const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: _selectedSubject,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                  items: widget.subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search Delegate
class NoteSearchDelegate extends SearchDelegate<Note?> {
  final List<Note> notes;

  NoteSearchDelegate({required this.notes});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => close(context, note),
        );
      },
    );
  }
}
