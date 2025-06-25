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

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('app_users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    final convoRef = FirebaseFirestore.instance
        .collection('pharmacyInbox')
        .orderBy('lastMessageAt', descending: true);

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
              hintText: "Search...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: convoRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final title = (doc['title'] ?? '').toString().toLowerCase();
                return title.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final userId = doc['userId']?.toString() ?? '';
                  final lastMessage = doc['lastMessage']?.toString() ?? '';
                  final lastTime = doc['lastMessageAt'] as Timestamp?;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: fetchUserProfile(userId),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) {
                        return const ListTile(title: Text("Loading user..."));
                      }

                      final userData = userSnap.data!;
                      final name = userData['name'] ?? 'Unknown';
                      final phone = userData['phone'] ?? "000";
                      final profileImage = userData['profileImage'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : const AssetImage('assets/zappq_icon.jpg') as ImageProvider,
                        ),
                        title: Text(name),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(formatTimestamp(lastTime), style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          widget.onSessionSelected(ChatSession(

                            userId: userId,

                            conversationId: doc.id,
                            userName: name,
                            phone:phone ,
                            userProfile: profileImage,
                          ));
                        },
                      );
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
