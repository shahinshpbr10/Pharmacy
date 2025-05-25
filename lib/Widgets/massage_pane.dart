
import 'package:flutter/material.dart';
import 'message_input_bar.dart';

class MessagePane extends StatelessWidget {
  const MessagePane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundImage: AssetImage('assets/user.png')),
              const SizedBox(width: 10),
              const Text("Shahinsh", style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(onPressed: () {}, child: const Text("Unread")),
              const SizedBox(width: 10),
              const Icon(Icons.bookmark_border),
              const SizedBox(width: 10),
              const Icon(Icons.call),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Align(alignment: Alignment.centerLeft, child: ChatBubble(text: "hey", isMe: false)),
                Align(alignment: Alignment.centerLeft, child: ChatBubble(text: "Need Med", isMe: false)),
                Align(alignment: Alignment.centerRight, child: ChatBubble(text: "hello", isMe: true)),
                Align(alignment: Alignment.centerRight, child: ChatBubble(text: "no Med Available", isMe: true)),
              ],
            ),
          ),
        ),

        // Input bar
        const MessageInputBar(),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
      ),
    );
  }
}
