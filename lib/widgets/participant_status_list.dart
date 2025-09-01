import 'package:flutter/material.dart';
import '../models/quiz_session_model.dart';

class ParticipantStatusList extends StatelessWidget {
  final QuizSessionModel session;
  final bool showStatusDot;

  const ParticipantStatusList({
    super.key,
    required this.session,
    this.showStatusDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final onlineParticipants = session.onlineParticipants;
    final reconnectingParticipants = session.reconnectingParticipants;
    final offlineParticipants = session.offlineParticipants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Online count
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${session.onlineCount} of ${session.totalCount} players online',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),

        // Online participants
        ..._buildParticipantList(onlineParticipants, Colors.green, 'online'),

        // Reconnecting participants
        if (reconnectingParticipants.isNotEmpty) ...[
          const Divider(),
          ..._buildParticipantList(
            reconnectingParticipants,
            Colors.orange,
            'reconnecting',
          ),
        ],

        // Offline participants
        if (offlineParticipants.isNotEmpty) ...[
          const Divider(),
          ..._buildParticipantList(offlineParticipants, Colors.grey, 'offline'),
        ],
      ],
    );
  }

  List<Widget> _buildParticipantList(
    List<QuizParticipant> participants,
    Color statusColor,
    String status,
  ) {
    return participants.map((participant) {
      String subtitle = status;
      if (status == 'reconnecting' && participant.disconnectedAt != null) {
        final timeLeft =
            const Duration(minutes: 1) -
            DateTime.now().difference(participant.disconnectedAt!);
        if (timeLeft.isNegative) {
          subtitle = 'connection timed out';
        } else {
          subtitle = 'reconnecting... ${timeLeft.inSeconds}s remaining';
        }
      }

      return ListTile(
        leading: showStatusDot
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        title: Text(participant.userName),
        subtitle: Text(subtitle, style: TextStyle(color: statusColor)),
        trailing: Text(
          'Score: ${participant.score}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
  }
}
