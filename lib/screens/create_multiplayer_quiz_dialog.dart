import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import './multiplayer_quiz_screen.dart';

class CreateMultiplayerQuizDialog extends StatefulWidget {
  final String subject;
  final String fileName;

  const CreateMultiplayerQuizDialog({
    super.key,
    required this.subject,
    required this.fileName,
  });

  @override
  CreateMultiplayerQuizDialogState createState() =>
      CreateMultiplayerQuizDialogState();
}

class CreateMultiplayerQuizDialogState
    extends State<CreateMultiplayerQuizDialog> {
  final QuizService _quizService = QuizService();
  String? _selectedGroupId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!AuthService.isSignedIn) {
        throw Exception('User must be signed in');
      }

      final user = AuthService.currentUser!;
      final userGroups = await GroupService.getUserGroups(user.uid);

      setState(() {
        _groups = userGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load groups: $e';
        _isLoading = false;
      });
    }
  }

  void _createSession() async {
    if (_selectedGroupId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (!AuthService.isSignedIn) {
        throw Exception('User must be signed in');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Multiplayer Quiz'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
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
                    'You are not a member of any groups yet.\nJoin or create a group to play multiplayer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedGroupId,
                    hint: const Text('Select a group'),
                    isExpanded: true,
                    items: _groups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group['id'] as String,
                            child: Text(group['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroupId = value;
                      });
                    },
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedGroupId == null || _isLoading
              ? null
              : _createSession,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Session'),
        ),
      ],
    );
  }
}
