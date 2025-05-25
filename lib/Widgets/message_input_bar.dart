
import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
          IconButton(icon: const Icon(Icons.grid_view), onPressed: () {}),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type the message to send",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
        ],
      ),
    );
  }
}
