import 'package:flutter/material.dart';
import '../Widgets/chat_pane.dart';
import '../Widgets/message_pane.dart';
import '../models/chat_session.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatSession? selectedSession;

  @override
  Widget build(BuildContext context) {
    final chatPane = selectedSession != null
        ? MessagePane(
      userId: selectedSession!.userId,
      conversationId: selectedSession!.conversationId,
      userName: selectedSession!.userName,
      userProfile: selectedSession!.userProfile,
    )
        : const Center(
      child: Text(
        'Select a conversation to start chatting',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: ChatListPane(
              onSessionSelected: (session) {
                setState(() {
                  selectedSession = session;
                });
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(flex: 4, child: chatPane),
        ],
      ),
    );
  }
}
