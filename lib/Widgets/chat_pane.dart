import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_session.dart';

class ChatListPane extends StatefulWidget {
  final void Function(ChatSession session) onSessionSelected;

  const ChatListPane({super.key, required this.onSessionSelected});

  @override
  State<ChatListPane> createState() => _ChatListPaneState();
}

class _ChatListPaneState extends State<ChatListPane> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute $ampm";
  }

  Future<List<Map<String, dynamic>>> fetchChatsWithUserData() async {
    final convoSnap = await FirebaseFirestore.instance
        .collection('pharmacyInbox')
        .orderBy('lastMessageAt', descending: true)
        .get();

    List<Map<String, dynamic>> chatItems = [];

    for (var doc in convoSnap.docs) {
      final userId = doc['userId'];
      final userSnap = await FirebaseFirestore.instance.collection('app_users').doc(userId).get();

      if (userSnap.exists) {
        final userData = userSnap.data()!;
        chatItems.add({
          'docId': doc.id,
          'userId': userId,
          'lastMessage': doc['lastMessage'] ?? '',
          'lastMessageAt': doc['lastMessageAt'] as Timestamp?,
          'name': userData['name'] ?? 'Unknown',
          'phone': userData['phone'] ?? '',
          'profileImage': userData['profileImage'] ?? '',
        });
      }
    }

    return chatItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Search by name...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchChatsWithUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final chatList = snapshot.data!;
              final filteredChats = _searchQuery.isEmpty
                  ? chatList
                  : chatList.where((chat) {
                final name = chat['name'].toString().toLowerCase();
                final phone = chat['phone'].toString().toLowerCase();
                return name.contains(_searchQuery) || phone.contains(_searchQuery);
              }).toList();

              if (filteredChats.isEmpty) {
                return const Center(child: Text("No matching chats"));
              }

              return ListView.builder(
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: chat['profileImage'] != null && chat['profileImage'].isNotEmpty
                          ? NetworkImage(chat['profileImage'])
                          : const AssetImage('assets/zappq_icon.jpg') as ImageProvider,
                    ),
                    title: Text(chat['name']),
                    subtitle: Text(chat['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      formatTimestamp(chat['lastMessageAt']),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      widget.onSessionSelected(ChatSession(
                        userId: chat['userId'],
                        conversationId: chat['docId'],
                        userName: chat['name'],
                        phone: chat['phone'],
                        userProfile: chat['profileImage'],
                      ));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
