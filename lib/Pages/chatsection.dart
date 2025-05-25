
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Widgets/chat_pane.dart';
import '../Widgets/massage_pane.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: const [
          Expanded(
            flex: 2,
            child: ChatListPane(),
          ),
          VerticalDivider(width: 1),
          Expanded(
            flex: 4,
            child: MessagePane(),
          ),
        ],
      ),
    );
  }
}
