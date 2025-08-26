import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

// Note model
class Note {
  final String id;
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

enum ExportFormat { pdf, docx }

// Note Manager Class - Reusable across the app
class NoteManager {
  static final NoteManager _instance = NoteManager._internal();
  factory NoteManager() => _instance;
  NoteManager._internal();

  List<Note> _notes = [];
  late Directory _notesDirectory;
  bool _initialized = false;

  List<Note> get notes => List.unmodifiable(_notes);

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _requestPermissions();
      await _createNotesDirectory();
      await _loadNotes();
      _initialized = true;
    } catch (e) {
      print('Error initializing NoteManager: $e');
      // Continue with empty notes list instead of throwing
      _notes = [];
      _initialized = true;
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), we need different permissions
      final status = await Permission.storage.request();
      if (status.isDenied) {
        print('Storage permission denied, but continuing...');
        // Don't throw exception, just log the issue
      }
    }
  }

  Future<void> _createNotesDirectory() async {
    try {
      Directory? externalDir;

      if (Platform.isAndroid) {
        // Try external storage first, fallback to app directory
        try {
          externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final paraNotesPath = '/storage/emulated/0/ParaNotes';
            _notesDirectory = Directory(paraNotesPath);
          }
        } catch (e) {
          print('External storage not available, using app directory');
          externalDir = await getApplicationDocumentsDirectory();
          _notesDirectory = Directory('${externalDir.path}/ParaNotes');
        }
      } else {
        // For iOS, use documents directory
        externalDir = await getApplicationDocumentsDirectory();
        _notesDirectory = Directory('${externalDir.path}/ParaNotes');
      }

      if (!await _notesDirectory.exists()) {
        await _notesDirectory.create(recursive: true);
      }
    } catch (e) {
      print('Error creating notes directory: $e');
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _notesDirectory = Directory('${appDir.path}/ParaNotes');
      if (!await _notesDirectory.exists()) {
        await _notesDirectory.create(recursive: true);
      }
    }
  }

  Future<void> _loadNotes() async {
    final notesFile = File('${_notesDirectory.path}/notes.json');

    if (await notesFile.exists()) {
      try {
        final jsonString = await notesFile.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _notes = jsonList.map((json) => Note.fromJson(json)).toList();
      } catch (e) {
        print('Error loading notes: $e');
        _notes = [];
      }
    }
  }

  Future<void> _saveNotes() async {
    try {
      final notesFile = File('${_notesDirectory.path}/notes.json');
      final jsonString = json.encode(
        _notes.map((note) => note.toJson()).toList(),
      );
      await notesFile.writeAsString(jsonString);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await _saveNotes();
    }
  }

  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    await _saveNotes();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    return _notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  List<Note> getNotesBySubject(String subject) {
    if (subject == 'All') return _notes;
    return _notes.where((note) => note.subject == subject).toList();
  }

  List<String> getSubjects() {
    Set<String> uniqueSubjects = {'All'};
    for (Note note in _notes) {
      uniqueSubjects.add(note.subject);
    }
    return uniqueSubjects.toList()..sort();
  }

  Future<String> exportNoteToPdf(Note note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Subject: ${note.subject}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Text(
                'Created: ${_formatDate(note.createdAt)}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Text(
                'Updated: ${_formatDate(note.updatedAt)}',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),
              pw.Text(note.content, style: pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    final fileName =
        '${note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf';
    final file = File('${_notesDirectory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> exportNoteToDocx(Note note) async {
    // Create a simple DOCX content
    final content =
        '''
${note.title}

Subject: ${note.subject}
Created: ${_formatDate(note.createdAt)}
Updated: ${_formatDate(note.updatedAt)}

${note.content}
''';

    final fileName =
        '${note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.docx';
    final file = File('${_notesDirectory.path}/$fileName');

    // For simplicity, we'll create a basic text file with .docx extension
    // In a real app, you'd use a proper DOCX library
    await file.writeAsString(content);
    return file.path;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Main Notepad Screen
class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final NoteManager _noteManager = NoteManager();
  String searchQuery = '';
  String selectedSubject = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNoteManager();
  }

  Future<void> _initializeNoteManager() async {
    try {
      await _noteManager.initialize();
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing storage: $e';
      });
    }
  }

  List<String> get subjects => _noteManager.getSubjects();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading notes...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeNoteManager();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (subject) {
              setState(() {
                selectedSubject = subject;
              });
            },
            itemBuilder: (context) => subjects
                .map(
                  (subject) =>
                      PopupMenuItem(value: subject, child: Text(subject)),
                )
                .toList(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF32CD32),
        foregroundColor: Colors.white,
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    final notes = _getFilteredNotes();

    if (_noteManager.notes.isEmpty) {
      return _buildEmptyState();
    }

    if (notes.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildNoteCard(notes[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button to create your first note',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No notes found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'No notes in this category',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32CD32).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.subject,
                    style: const TextStyle(
                      color: Color(0xFF32CD32),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _openNote(note),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download, size: 18),
                  SizedBox(width: 8),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editNote(note);
                break;
              case 'export':
                _showExportDialog(note);
                break;
              case 'delete':
                _deleteNote(note);
                break;
            }
          },
        ),
      ),
    );
  }

  List<Note> _getFilteredNotes() {
    List<Note> filtered = _noteManager.notes;

    // Filter by subject
    if (selectedSubject != 'All') {
      filtered = _noteManager.getNotesBySubject(selectedSubject);
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = _noteManager.searchNotes(searchQuery);
    }

    // Sort by updated date (newest first)
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return filtered;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _createNewNote() {
    _openNoteEditor();
  }

  void _openNote(Note note) {
    _openNoteEditor(note: note);
  }

  void _editNote(Note note) {
    _openNoteEditor(note: note);
  }

  void _openNoteEditor({Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (title, content, subject) async {
            if (note != null) {
              // Update existing note
              note.title = title;
              note.content = content;
              note.subject = subject;
              note.updatedAt = DateTime.now();
              await _noteManager.updateNote(note);
            } else {
              // Create new note
              final newNote = Note(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                content: content,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                subject: subject,
              );
              await _noteManager.addNote(newNote);
            }
            setState(() {});
          },
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _noteManager.deleteNote(note.id);
              setState(() {});
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Notes'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Note'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportNote(note, ExportFormat.pdf);
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportNote(note, ExportFormat.docx);
            },
            child: const Text('Word'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportNote(Note note, ExportFormat format) async {
    try {
      String filePath;

      if (format == ExportFormat.pdf) {
        filePath = await _noteManager.exportNoteToPdf(note);
      } else {
        filePath = await _noteManager.exportNoteToDocx(note);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note exported to: $filePath'),
          backgroundColor: const Color(0xFF32CD32),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareXFiles([XFile(filePath)]);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Note Editor Screen
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content, String subject) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController subjectController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    contentController = TextEditingController(text: widget.note?.content ?? '');
    subjectController = TextEditingController(
      text: widget.note?.subject ?? 'General',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF32CD32),
        foregroundColor: Colors.white,
        title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Subject field
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g., Work, Personal, Study...',
              ),
            ),
            const SizedBox(height: 16),

            // Title field
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Content field
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final subject = subjectController.text.trim().isEmpty
        ? 'General'
        : subjectController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSave(title, content, subject);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.note != null ? 'Note updated' : 'Note saved'),
        backgroundColor: const Color(0xFF32CD32),
      ),
    );
  }
}

// Example of how to use NoteManager in other parts of the app
class NotesViewer extends StatelessWidget {
  final NoteManager _noteManager = NoteManager();

  NotesViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes Viewer')),
      body: FutureBuilder(
        future: _noteManager.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notes = _noteManager.notes;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.subject),
                trailing: Text(_formatDate(note.updatedAt)),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
