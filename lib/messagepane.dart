import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessagePane extends StatelessWidget {
  const MessagePane({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ChatHeader(),
        const Expanded(child: MessageList()),
        const ChatInputBar(),
      ],
    );
  }
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          const CircleAvatar(backgroundImage: AssetImage('assets/profile.jpg')),
          const SizedBox(width: 10),
          const Text("Shahinsh", style: TextStyle(color: Colors.black)),
        ],
      ),
      actions: const [
        Icon(Icons.push_pin, color: Colors.black),
        SizedBox(width: 12),
        Icon(Icons.call, color: Colors.black),
        SizedBox(width: 12),
      ],
    );
  }
}

class MessageList extends StatelessWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Align(alignment: Alignment.centerLeft, child: ChatBubble(text: "hey")),
        Align(alignment: Alignment.centerLeft, child: ChatBubble(text: "Need Med")),
        Align(alignment: Alignment.centerRight, child: ChatBubble(text: "hello", isMe: true)),
        Align(alignment: Alignment.centerRight, child: ChatBubble(text: "no Med Available", isMe: true)),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const ChatBubble({required this.text, this.isMe = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFF1F1F1),
      child: Row(
        children: [
          const Icon(Icons.camera_alt),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Type your message...'),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
          const Icon(Icons.mic),
        ],
      ),
    );
  }
}
