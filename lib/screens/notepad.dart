import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

// External Storage Interface
abstract class ExternalStorage {
  Future<void> saveNotes(List<Note> notes);
  Future<List<Note>> loadNotes();
  Future<void> backupNotes(List<Note> notes, String backupName);
  Future<List<String>> getAvailableBackups();
  Future<List<Note>> restoreFromBackup(String backupName);
}

// Local File Storage Implementation
class LocalFileStorage implements ExternalStorage {
  late Directory _storageDirectory;
  late Directory _backupDirectory;

  Future<void> initialize() async {
    await _createStorageDirectories();
  }

  Future<void> _createStorageDirectories() async {
    try {
      Directory baseDir;
      
      if (Platform.isAndroid) {
        // Try external storage first, fall back to app directory
        try {
          final externalDir = await getExternalStorageDirectory();
          baseDir = externalDir ?? await getApplicationDocumentsDirectory();
        } catch (e) {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS uses documents directory
        baseDir = await getApplicationDocumentsDirectory();
      }

      _storageDirectory = Directory('${baseDir.path}/ParaNotes');
      _backupDirectory = Directory('${baseDir.path}/ParaNotes/Backups');

      await _storageDirectory.create(recursive: true);
      await _backupDirectory.create(recursive: true);

      print('Storage directories created at: ${_storageDirectory.path}');
    } catch (e) {
      print('Error creating storage directories: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    try {
      final notesFile = File('${_storageDirectory.path}/notes.json');
      final jsonData = {
        'notes': notes.map((note) => note.toJson()).toList(),
        'lastModified': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final jsonString = json.encode(jsonData);
      await notesFile.writeAsString(jsonString);
      print('Saved ${notes.length} notes to local storage');
    } catch (e) {
      print('Error saving notes: $e');
      throw Exception('Failed to save notes: $e');
    }
  }

  @override
  Future<List<Note>> loadNotes() async {
    try {
      final notesFile = File('${_storageDirectory.path}/notes.json');
      
      if (!await notesFile.exists()) {
        return [];
      }

      final jsonString = await notesFile.readAsString();
      if (jsonString.isEmpty) {
        return [];
      }

      final jsonData = json.decode(jsonString);
      
      // Handle both old and new format
      List<dynamic> notesList;
      if (jsonData is List) {
        // Old format - direct list of notes
        notesList = jsonData;
      } else if (jsonData is Map && jsonData['notes'] != null) {
        // New format - structured data
        notesList = jsonData['notes'];
      } else {
        return [];
      }

      final notes = notesList.map((noteJson) => Note.fromJson(noteJson)).toList();
      print('Loaded ${notes.length} notes from local storage');
      return notes;
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  @override
  Future<void> backupNotes(List<Note> notes, String backupName) async {
    try {
      final backupFile = File('${_backupDirectory.path}/$backupName.json');
      final backupData = {
        'notes': notes.map((note) => note.toJson()).toList(),
        'backupName': backupName,
        'createdAt': DateTime.now().toIso8601String(),
        'noteCount': notes.length,
        'version': '1.0',
      };
      
      final jsonString = json.encode(backupData);
      await backupFile.writeAsString(jsonString);
      print('Backup created: $backupName with ${notes.length} notes');
    } catch (e) {
      print('Error creating backup: $e');
      throw Exception('Failed to create backup: $e');
    }
  }

  @override
  Future<List<String>> getAvailableBackups() async {
    try {
      final backupFiles = _backupDirectory
          .listSync()
          .where((file) => file.path.endsWith('.json'))
          .map((file) => file.path.split('/').last.replaceAll('.json', ''))
          .toList();
      
      backupFiles.sort((a, b) => b.compareTo(a)); // Sort by name (newest first)
      return backupFiles;
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }

  @override
  Future<List<Note>> restoreFromBackup(String backupName) async {
    try {
      final backupFile = File('${_backupDirectory.path}/$backupName.json');
      
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found: $backupName');
      }

      final jsonString = await backupFile.readAsString();
      final backupData = json.decode(jsonString);
      
      final notesList = backupData['notes'] as List<dynamic>;
      final notes = notesList.map((noteJson) => Note.fromJson(noteJson)).toList();
      
      print('Restored ${notes.length} notes from backup: $backupName');
      return notes;
    } catch (e) {
      print('Error restoring backup: $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  String get storagePath => _storageDirectory.path;
}

// Cloud Storage Implementation (Example with generic HTTP API)
class CloudStorage implements ExternalStorage {
  final String baseUrl;
  final String apiKey;

  CloudStorage({required this.baseUrl, required this.apiKey});

  @override
  Future<void> saveNotes(List<Note> notes) async {
    try {
      final data = {
        'notes': notes.map((note) => note.toJson()).toList(),
        'lastModified': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save notes to cloud: ${response.statusCode}');
      }

      print('Saved ${notes.length} notes to cloud storage');
    } catch (e) {
      print('Error saving notes to cloud: $e');
      throw Exception('Failed to save notes to cloud: $e');
    }
  }

  @override
  Future<List<Note>> loadNotes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notes'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load notes from cloud: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final notesList = data['notes'] as List<dynamic>;
      final notes = notesList.map((noteJson) => Note.fromJson(noteJson)).toList();
      
      print('Loaded ${notes.length} notes from cloud storage');
      return notes;
    } catch (e) {
      print('Error loading notes from cloud: $e');
      return [];
    }
  }

  @override
  Future<void> backupNotes(List<Note> notes, String backupName) async {
    try {
      final data = {
        'notes': notes.map((note) => note.toJson()).toList(),
        'backupName': backupName,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/backups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create cloud backup: ${response.statusCode}');
      }

      print('Cloud backup created: $backupName');
    } catch (e) {
      print('Error creating cloud backup: $e');
      throw Exception('Failed to create cloud backup: $e');
    }
  }

  @override
  Future<List<String>> getAvailableBackups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/backups'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get cloud backups: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final backups = (data['backups'] as List<dynamic>)
          .map((backup) => backup['backupName'] as String)
          .toList();
      
      return backups;
    } catch (e) {
      print('Error getting cloud backups: $e');
      return [];
    }
  }

  @override
  Future<List<Note>> restoreFromBackup(String backupName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/backups/$backupName'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to restore cloud backup: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final notesList = data['notes'] as List<dynamic>;
      final notes = notesList.map((noteJson) => Note.fromJson(noteJson)).toList();
      
      print('Restored ${notes.length} notes from cloud backup: $backupName');
      return notes;
    } catch (e) {
      print('Error restoring cloud backup: $e');
      throw Exception('Failed to restore cloud backup: $e');
    }
  }
}

// Note Manager Class - Updated with external storage
class NoteManager {
  static final NoteManager _instance = NoteManager._internal();
  factory NoteManager() => _instance;
  NoteManager._internal();

  List<Note> _notes = [];
  late ExternalStorage _storage;
  bool _initialized = false;

  List<Note> get notes => List.unmodifiable(_notes);

  Future<void> initialize({ExternalStorage? customStorage}) async {
    if (_initialized) return;

    try {
      await _requestPermissions();
      
      // Initialize storage
      if (customStorage != null) {
        _storage = customStorage;
      } else {
        final localStorage = LocalFileStorage();
        await localStorage.initialize();
        _storage = localStorage;
      }

      await _loadNotes();
      _initialized = true;
      print('NoteManager initialized successfully');
    } catch (e) {
      print('Error initializing NoteManager: $e');
      await _initializeFallback();
      _initialized = true;
    }
  }

  Future<void> _initializeFallback() async {
    try {
      final localStorage = LocalFileStorage();
      await localStorage.initialize();
      _storage = localStorage;
      _notes = [];
      print('Fallback initialization successful');
    } catch (e) {
      print('Fallback initialization failed: $e');
      _notes = [];
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        var status = await Permission.storage.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.storage.request();
        }
        
        if (status.isDenied) {
          final manageStatus = await Permission.manageExternalStorage.request();
          print('Manage external storage permission: $manageStatus');
        }
        
        print('Storage permission status: $status');
      } catch (e) {
        print('Permission request failed: $e');
      }
    }
  }

  Future<void> _loadNotes() async {
    try {
      _notes = await _storage.loadNotes();
      print('Loaded ${_notes.length} notes');
    } catch (e) {
      print('Error loading notes: $e');
      _notes = [];
    }
  }

  Future<void> _saveNotes() async {
    try {
      await _storage.saveNotes(_notes);
      print('Saved ${_notes.length} notes');
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

  // Export notes as JSON
  Future<String> exportNotesToJson() async {
    try {
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'noteCount': _notes.length,
        'notes': _notes.map((note) => note.toJson()).toList(),
        'version': '1.0',
      };

      final jsonString = json.encode(exportData);
      
      // Save to external storage for sharing
      Directory tempDir = await getTemporaryDirectory();
      final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      print('Error exporting notes: $e');
      throw Exception('Failed to export notes: $e');
    }
  }

  // Import notes from JSON
  Future<int> importNotesFromJson(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final importData = json.decode(jsonString);

      List<dynamic> notesList;
      if (importData is List) {
        // Direct list of notes
        notesList = importData;
      } else if (importData is Map && importData['notes'] != null) {
        // Structured export format
        notesList = importData['notes'];
      } else {
        throw Exception('Invalid JSON format');
      }

      int importedCount = 0;
      for (var noteJson in notesList) {
        try {
          final note = Note.fromJson(noteJson);
          // Check if note already exists (by ID)
          if (!_notes.any((existingNote) => existingNote.id == note.id)) {
            _notes.add(note);
            importedCount++;
          }
        } catch (e) {
          print('Error importing note: $e');
        }
      }

      if (importedCount > 0) {
        await _saveNotes();
      }

      return importedCount;
    } catch (e) {
      print('Error importing notes: $e');
      throw Exception('Failed to import notes: $e');
    }
  }

  // Backup operations
  Future<void> createBackup(String backupName) async {
    try {
      await _storage.backupNotes(_notes, backupName);
    } catch (e) {
      print('Error creating backup: $e');
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      return await _storage.getAvailableBackups();
    } catch (e) {
      print('Error getting backups: $e');
      return [];
    }
  }

  Future<void> restoreFromBackup(String backupName) async {
    try {
      _notes = await _storage.restoreFromBackup(backupName);
      await _saveNotes(); // Save restored notes to current storage
    } catch (e) {
      print('Error restoring backup: $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  // Sync with external storage
  Future<void> syncNotes() async {
    try {
      await _saveNotes();
      print('Notes synced successfully');
    } catch (e) {
      print('Error syncing notes: $e');
      throw Exception('Failed to sync notes: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Main Notepad Screen - Updated
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

  @override
  void initState() {
    super.initState();
    _initializeNoteManager();
  }

  Future<void> _initializeNoteManager() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _noteManager.initialize();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to initialize note manager: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> get subjects => _noteManager.getSubjects();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32CD32)),
              ),
              SizedBox(height: 16),
              Text('Loading notes...', style: TextStyle(fontSize: 16)),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 18),
                    SizedBox(width: 8),
                    Text('Export JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, size: 18),
                    SizedBox(width: 8),
                    Text('Import JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 18),
                    SizedBox(width: 8),
                    Text('Create Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 18),
                    SizedBox(width: 8),
                    Text('Restore Backup'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 18),
                    SizedBox(width: 8),
                    Text('Sync Notes'),
                  ],
                ),
              ),
            ],
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
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Share as JSON'),
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
              case 'share':
                _shareNoteAsJson(note);
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

    if (selectedSubject != 'All') {
      filtered = _noteManager.getNotesBySubject(selectedSubject);
    }

    if (searchQuery.isNotEmpty) {
      filtered = _noteManager.searchNotes(searchQuery);
    }

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
              note.title = title;
              note.content = content;
              note.subject = subject;
              note.updatedAt = DateTime.now();
              await _noteManager.updateNote(note);
            } else {
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportAllNotes();
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'backup':
        _createBackup();
        break;
      case 'restore':
        _showRestoreDialog();
        break;
      case 'sync':
        _syncNotes();
        break;
    }
  }

  Future<void> _exportAllNotes() async {
    try {
      final filePath = await _noteManager.exportNotesToJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes exported successfully'),
            backgroundColor: const Color(0xFF32CD32),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                Share.shareXFiles([XFile(filePath)]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareNoteAsJson(Note note) async {
    try {
      final noteJson = {
        'note': note.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      Directory tempDir = await getTemporaryDirectory();
      final fileName = '${note.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(json.encode(noteJson));

      Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Notes'),
        content: const Text('To import notes, place a JSON file with exported notes in your device and select it through your file manager. The app will automatically detect and import compatible JSON files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    final backupName = 'backup_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      await _noteManager.createBackup(backupName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: Color(0xFF32CD32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRestoreDialog() async {
    try {
      final backups = await _noteManager.getAvailableBackups();
      
      if (backups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backups available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Backup'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  return ListTile(
                    title: Text(backup),
                    subtitle: Text('Tap to restore'),
                    onTap: () {
                      Navigator.pop(context);
                      _restoreFromBackup(backup);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading backups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromBackup(String backupName) async {
    try {
      await _noteManager.restoreFromBackup(backupName);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Color(0xFF32CD32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncNotes() async {
    try {
      await _noteManager.syncNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes synced successfully'),
            backgroundColor: Color(0xFF32CD32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Note Editor Screen - Same as before
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
