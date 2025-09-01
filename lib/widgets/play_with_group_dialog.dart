import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/quiz_service.dart';
import '../models/quiz_session_model.dart';
import '../screens/multiplayer_quiz_screen.dart';

class PlayWithGroupDialog extends StatefulWidget {
  final String subject;
  final String fileName;
  final String groupId;

  const PlayWithGroupDialog({
    super.key,
    required this.subject,
    required this.fileName,
    required this.groupId,
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
    _selectedGroupId = widget.groupId;
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
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.8;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                _showExistingSessions ? 'Join Quiz Session' : 'Play with Group',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Content
              Flexible(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),

              // Actions
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),

          if (_groups.isEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You are not a member of any groups. Join a group to play multiplayer quizzes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

          if (_groups.isNotEmpty)
            _showExistingSessions
                ? _buildActiveSessionsList()
                : _buildCreateSession(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      children: [
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Select Group'),
              value: _selectedGroupId,
              isExpanded: true,
              items: _groups.map<DropdownMenuItem<String>>((group) {
                return DropdownMenuItem<String>(
                  value: group['id'] as String,
                  child: Text(
                    group['name'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedGroupId != null && !_isLoading
              ? _createSession
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Create Quiz Session'),
        ),
      ],
    );
  }

  Widget _buildActiveSessionsList() {
    final activeSessions = _activeSessions.values.toList();

    if (activeSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No active quiz sessions found for this subject.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: activeSessions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final session = activeSessions[index];
          final group = _groups.firstWhere(
            (g) => g['id'] == session.groupId,
            orElse: () => {'name': 'Unknown Group'},
          );

          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.participants.length} participants • '
                          '${session.isWaiting ? 'Waiting' : 'In Progress'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: session.isWaiting
                        ? () => _joinSession(session)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
