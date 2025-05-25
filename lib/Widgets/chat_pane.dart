
import 'package:flutter/material.dart';

class ChatListPane extends StatelessWidget {
  const ChatListPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Row(
              children: [
                Text("Chats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.filter_list),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: const [
              FilterChip(label: Text("Unread"), onSelected: null),
              FilterChip(label: Text("Shipped"), onSelected: null),
              FilterChip(label: Text("Delivered"), onSelected: null),
              FilterChip(label: Text("New"), onSelected: null),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(backgroundImage: AssetImage('assets/user.png')),
                  title: const Text("Shahinsh"),
                  subtitle: const Text("needed med urgent"),
                  trailing: Text("2:50", style: TextStyle(fontSize: 12)),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
