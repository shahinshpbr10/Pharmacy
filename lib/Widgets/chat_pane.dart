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
  String _messageTypeFilter = 'All'; // 'All', 'Image', 'Voice', 'Text'

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

  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    final userSnap = await FirebaseFirestore.instance.collection('app_users').doc(userId).get();
    return userSnap.exists ? userSnap.data() : null;
  }


  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        setState(() {
          _messageTypeFilter = value;
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        const PopupMenuItem(value: 'Image', child: Text('Image')),
        const PopupMenuItem(value: 'Voice', child: Text('Voice')),
        const PopupMenuItem(value: 'Text', child: Text('Text')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const Text("Chats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildFilterMenu(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Search by name or phone...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pharmacyInbox')
                .orderBy('lastMessageAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No chats found"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final userId = doc['userId'];
                  final lastMessage = doc['lastMessage'] ?? '';
                  final lastMessageAt = doc['lastMessageAt'] as Timestamp?;

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: fetchUserData(userId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const SizedBox.shrink();
                      final userData = userSnapshot.data!;
                      final name = userData['name'] ?? 'Unknown';
                      final phone = userData['phone'] ?? '';
                      final profileImage = userData['profileImage'] ?? '';

                      final nameMatch = name.toLowerCase().contains(_searchQuery);
                      final phoneMatch = phone.toLowerCase().contains(_searchQuery);
                      final matchesSearch = _searchQuery.isEmpty || nameMatch || phoneMatch;

                      final matchesFilter = _messageTypeFilter == 'All' ||
                          (_messageTypeFilter == 'Image' && lastMessage.toLowerCase() == 'image') ||
                          (_messageTypeFilter == 'Voice' && lastMessage.toLowerCase() == 'voice') ||
                          (_messageTypeFilter == 'Text' &&
                              lastMessage.toLowerCase() != 'image' &&
                              lastMessage.toLowerCase() != 'voice');

                      if (!matchesSearch || !matchesFilter) return const SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : const AssetImage('assets/zappq_icon.jpg') as ImageProvider,
                        ),
                        title: Text(name),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          formatTimestamp(lastMessageAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          widget.onSessionSelected(ChatSession(
                            userId: userId,
                            conversationId: doc.id,
                            userName: name,
                            phone: phone,
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
