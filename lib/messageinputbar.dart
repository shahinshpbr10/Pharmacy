import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.camera_alt),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(hintText: 'Type the message to send'),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
          const Icon(Icons.mic),
        ],
      ),
    );
  }
}
