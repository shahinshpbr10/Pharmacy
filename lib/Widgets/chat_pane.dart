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
  String _filterType = 'All'; // 'All', 'Unread', 'Archived', 'Date'
  DateTime? _selectedDate;

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
      onSelected: (value) async {
        if (value == 'Date') {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
              _filterType = 'Date';
            });
          }
        } else {
          setState(() {
            _filterType = value;
            _selectedDate = null;
          });
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        const PopupMenuItem(value: 'Unread', child: Text('Unread')),
        const PopupMenuItem(value: 'Date', child: Text('Filter by Date')),
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
        if (_filterType != 'All')
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8),
            child: Row(
              children: [
                Text(
                  "Filter: $_filterType${_filterType == 'Date' && _selectedDate != null ? ' (${_selectedDate!.toLocal().toString().split(' ')[0]})' : ''}",
                  style: const TextStyle(color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    setState(() {
                      _filterType = 'All';
                      _selectedDate = null;
                    });
                  },
                )
              ],
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
                  final data = doc.data() as Map<String, dynamic>;

                  final userId = data['userId'];
                  final lastMessage = data['lastMessage'] ?? '';
                  final lastMessageAt = data['lastMessageAt'] as Timestamp?;
                  final isRead = data['isRead'] == true;
                  final isUnread = !isRead;
                  final isArchived = data['isArchived'] == true;

                  final timestampDate = lastMessageAt?.toDate();
                  final isSameDate = _selectedDate == null ||
                      (timestampDate != null &&
                          timestampDate.year == _selectedDate!.year &&
                          timestampDate.month == _selectedDate!.month &&
                          timestampDate.day == _selectedDate!.day);

                  final matchesFilter = _filterType == 'All' ||
                      (_filterType == 'Unread' && isUnread) ||
                      (_filterType == 'Archived' && isArchived) ||
                      (_filterType == 'Date' && isSameDate);

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: fetchUserData(userId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !matchesFilter) return const SizedBox.shrink();

                      final userData = userSnapshot.data!;
                      final name = userData['name'] ?? 'Unknown';
                      final phone = userData['phone'] ?? '';
                      final profileImage = userData['profileImage'] ?? '';

                      final nameMatch = name.toLowerCase().contains(_searchQuery);
                      final phoneMatch = phone.toLowerCase().contains(_searchQuery);
                      final matchesSearch = _searchQuery.isEmpty || nameMatch || phoneMatch;

                      if (!matchesSearch) return const SizedBox.shrink();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : const AssetImage('assets/zappq_icon.jpg') as ImageProvider,
                        ),
                        title: Text(name),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            const SizedBox(width: 10),
                            Text(
                              formatTimestamp(lastMessageAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () async {
                          widget.onSessionSelected(ChatSession(
                            userId: userId,
                            conversationId: doc.id,
                            userName: name,
                            phone: phone,
                            userProfile: profileImage,
                          ));

                          // Update isRead to true if it's currently false
                          if (!isRead) {
                            await FirebaseFirestore.instance
                                .collection('pharmacyInbox')
                                .doc(doc.id)
                                .update({'isRead': true});
                          }
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
