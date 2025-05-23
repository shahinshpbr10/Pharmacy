import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class ChatItem {
  final String name;
  final String subtitle;
  final String time;
  final String? avatar;


  ChatItem({required this.name, required this.subtitle, required this.time, this.avatar});
}


class ChatListPane extends StatelessWidget {
  final String title;
  final List<ChatItem> items;

  const ChatListPane({required this.title, required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.filter_list),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purpleAccent),
                  title: Text(item.name),
                  subtitle: Text(item.subtitle),
                  trailing: Text(item.time),
                  onTap: () {}, // Open detail
                );
              },
            ),
          )
        ],
      ),
    );
  }
}


class DummyList extends StatelessWidget {
  const DummyList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (_, index) {
        return ListTile(
          leading: const CircleAvatar(backgroundImage: AssetImage('assets/profile.jpg')),
          title: const Text("Shahinsh"),
          subtitle: const Text("need med urget"),
          trailing: const Text("2:50"),
          onTap: () {},
        );
      },
    );
  }
}
