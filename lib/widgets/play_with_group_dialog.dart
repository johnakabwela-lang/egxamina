import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/quiz_service.dart';
import '../models/quiz_session_model.dart';
import '../screens/multiplayer_quiz_screen.dart';

class PlayWithGroupDialog extends StatefulWidget {
  final String subject;
  final String fileName;
  final String groupId; // Add groupId parameter

  const PlayWithGroupDialog({
    super.key,
    required this.subject,
    required this.fileName,
    required this.groupId, // Make groupId required
  });

  @override
  State<PlayWithGroupDialog> createState() => _PlayWithGroupDialogState();
}

class _PlayWithGroupDialogState extends State<PlayWithGroupDialog> {
  final QuizService _quizService = QuizService();
  String? _selectedGroupId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  String? _errorMessage;
  bool _showExistingSessions = false;
  final Map<String, QuizSessionModel> _activeSessions = {};

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId; // Auto-select the group
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!AuthService.isSignedIn) {
        throw Exception('You must be signed in to play with groups');
      }

      final user = AuthService.currentUser!;
      final userGroups = await GroupService.getUserGroups(user.uid);

      setState(() {
        _groups = userGroups;
        _isLoading = false;
      });

      if (_groups.isNotEmpty) {
        _loadActiveSessions();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load groups: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveSessions() async {
    for (final group in _groups) {
      _quizService.getActiveGroupSessions(group['id']).listen((sessions) {
        if (mounted) {
          setState(() {
            for (var session in sessions) {
              if (session.quizName == '${widget.subject} Quiz') {
                _activeSessions[session.id] = session;
              }
            }
          });
        }
      });
    }
  }

  Future<void> _createSession() async {
    if (_selectedGroupId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!AuthService.isSignedIn) {
        throw Exception('You must be signed in to create a quiz session');
      }

      final user = AuthService.currentUser!;
      final profile = await AuthService.getCurrentUserProfile();

      final session = await _quizService.startMultiplayerSession(
        groupId: _selectedGroupId!,
        quizName: '${widget.subject} Quiz',
        hostUserId: user.uid,
        hostUserName: profile?.name ?? user.email ?? 'Anonymous User',
      );

      if (mounted) {
        Navigator.pushReplacement(
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinSession(QuizSessionModel session) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!AuthService.isSignedIn) {
        throw Exception('You must be signed in to join a quiz session');
      }

      final user = AuthService.currentUser!;
      final profile = await AuthService.getCurrentUserProfile();

      await _quizService.joinSession(
        sessionId: session.id,
        userId: user.uid,
        userName: profile?.name ?? user.email ?? 'Anonymous User',
      );

      if (mounted) {
        Navigator.pushReplacement(
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining session: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _showExistingSessions ? 'Join Quiz Session' : 'Play with Group',
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_groups.isEmpty && !_isLoading)
                    const Text(
                      'You are not a member of any groups. Join a group to play multiplayer quizzes.',
                      textAlign: TextAlign.center,
                    ),
                  if (_showExistingSessions)
                    _buildActiveSessionsList()
                  else
                    _buildCreateSession(),
                ],
              ),
            ),
      actions: [
        if (!_isLoading && _groups.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                _showExistingSessions = !_showExistingSessions;
              });
            },
            child: Text(_showExistingSessions ? 'Create New' : 'Join Existing'),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildCreateSession() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Select Group'),
          value: _selectedGroupId,
          items: _groups.map<DropdownMenuItem<String>>((group) {
            return DropdownMenuItem<String>(
              value: group['id'] as String,
              child: Text(group['name'] as String),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGroupId = value;
            });
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedGroupId != null && !_isLoading
              ? _createSession
              : null,
          child: const Text('Create Quiz Session'),
        ),
      ],
    );
  }

  Widget _buildActiveSessionsList() {
    final activeSessions = _activeSessions.values.toList();

    if (activeSessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No active quiz sessions found for this subject.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: activeSessions.length,
      itemBuilder: (context, index) {
        final session = activeSessions[index];
        final group = _groups.firstWhere(
          (g) => g['id'] == session.groupId,
          orElse: () => {'name': 'Unknown Group'},
        );

        return ListTile(
          title: Text(group['name'] as String),
          subtitle: Text(
            '${session.participants.length} participants | '
            '${session.isWaiting ? 'Waiting' : 'In Progress'}',
          ),
          trailing: ElevatedButton(
            onPressed: session.isWaiting ? () => _joinSession(session) : null,
            child: const Text('Join'),
          ),
        );
      },
    );
  }
}
