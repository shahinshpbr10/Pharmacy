import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'message_input_bar.dart';

class MessagePane extends StatefulWidget {
  final String userId;
  final String conversationId;
  final String userName;
  final String? userProfile;
  final String? phone;

  const MessagePane({
    super.key,
    required this.userId,
    required this.conversationId,
    required this.userName,
    this.userProfile, this.phone,
  });

  @override
  State<MessagePane> createState() => _MessagePaneState();
}

class _MessagePaneState extends State<MessagePane> {
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  Future<void> sendImageMessage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      final messageRef = FirebaseFirestore.instance
          .collection('app_users')
          .doc(widget.userId)
          .collection('pharmacyChats')
          .doc('conversations')
          .collection('items')
          .doc(widget.conversationId)
          .collection('messages');

      await messageRef.add({
        'text': '', // leave blank
        'type': 'image',
        'fileUrl': imageUrl,
        'isUser': false,
        'isRead': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('pharmacyInbox')
          .doc(widget.userId)
          .update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': '[Image]', // optional, can show preview
      });
    } catch (e) {
      debugPrint('Error sending image message: $e');
    }
  }

  Future<void> _showOrderDialog(BuildContext context) {
    String _status = 'pending';
    double _totalPrice = 0.0;
    List<Map<String, dynamic>> _medicines = [];

    final _medicineController = TextEditingController();
    final _priceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addMedicine() {
              if (_formKey.currentState?.validate() ?? false) {
                final medicinePrice = double.tryParse(_priceController.text) ?? 0.0;

                setState(() {
                  _medicines.add({
                    'name': _medicineController.text.trim(),
                    'price': medicinePrice,
                  });
                  _totalPrice += medicinePrice;
                });

                _medicineController.clear();
                _priceController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Medicine added!'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }

            void removeMedicine(int index) {
              setState(() {
                _totalPrice -= _medicines[index]['price'];
                _medicines.removeAt(index);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Add Order Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 500),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Medicine Name Input
                        TextFormField(
                          controller: _medicineController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Medicine Name',
                            hintText: 'Enter medicine name',
                            prefixIcon: Icon(Icons.medical_services, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter medicine name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Price Input
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price (\$)',
                            hintText: 'Enter price',
                            prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.green.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Enter valid price > 0';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: addMedicine,
                            icon: Icon(Icons.add_circle),
                            label: Text('Add Medicine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Medicines List
                        if (_medicines.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.list_alt, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Added Medicines (${_medicines.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),

                                // Medicine Items
                                ...List.generate(_medicines.length, (index) {
                                  final medicine = _medicines[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.medication, color: Colors.green, size: 20),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                medicine['name'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '\$${medicine['price'].toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => removeMedicine(index),
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          iconSize: 20,
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Total Price Display
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade200,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calculate, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${_totalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    _medicineController.dispose();
                    _priceController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _medicines.isEmpty ? null : () async {
                    try {
                      await FirebaseFirestore.instance.collection('pharmacyorders').add({
                        'status': _status,
                        'patientName': widget.userName,
                        'phone':widget.phone,
                        'medicines': _medicines,
                        'totalPrice': _totalPrice,
                        'createdAt': FieldValue.serverTimestamp(),
                        'uid': widget.userId,
                      });

                      _medicineController.dispose();
                      _priceController.dispose();
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Order saved successfully!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(child: Text('Error: ${e.toString()}')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text('Save Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _medicines.isEmpty ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            );
          },
        );
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final messageRef = FirebaseFirestore.instance
          .collection('app_users')
          .doc(widget.userId)
          .collection('pharmacyChats')
          .doc('conversations')
          .collection('items')
          .doc(widget.conversationId)
          .collection('messages');

      await messageRef.add({
        'text': text.trim(),
        'type': 'text',
        'fileUrl': '',
        'isUser': false,
        'isRead': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('pharmacyInbox')
          .doc(widget.userId)
          .update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessage': text.trim(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }


  String _selectedStatus = 'pending';
  List<String> _statusOptions = [
    'pending', 'approved', 'packed', 'in-Transit', 'delivered', 'completed'
  ];
  Future<void> updateOrderStatus(String status) async {
    try {
      // Query the pharmacyorders collection to find the order by uid and patientName
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('pharmacyorders')
          .where('uid', isEqualTo: widget.userId) // Match the uid
          .where('patientName', isEqualTo: widget.userName) // Match the patient name
          .get();

      if (orderSnapshot.docs.isNotEmpty) {
        // Get the document reference
        final orderDoc = orderSnapshot.docs.first;

        // Update the status of the order
        await orderDoc.reference.update({
          'status': status, // Update the status field
          'updatedAt': FieldValue.serverTimestamp(), // Update the timestamp
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order not found for ${widget.userName}')),
        );
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  Set<String> selectedMessageIds = {};
  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  Future<void> deleteSelectedMessages() async {
    final batch = FirebaseFirestore.instance.batch();
    final messagesRef = FirebaseFirestore.instance
        .collection('app_users')
        .doc(widget.userId)
        .collection('pharmacyChats')
        .doc('conversations')
        .collection('items')
        .doc(widget.conversationId)
        .collection('messages');

    for (String id in selectedMessageIds) {
      final docRef = messagesRef.doc(id);
      batch.delete(docRef);
    }

    await batch.commit();

    setState(() {
      selectedMessageIds.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('app_users')
        .doc(widget.userId)
        .collection('pharmacyChats')
        .doc('conversations')
        .collection('items')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('createdAt');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: (widget.userProfile != null && widget.userProfile!.isNotEmpty)
                    ? NetworkImage(widget.userProfile!)
                    : const AssetImage('assets/zappq_icon.jpg') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Text(
                widget.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),

              // Dropdown (Order Status)
              DropdownButton<String>(
                value: _selectedStatus,
                onChanged: (newStatus) {
                  setState(() {
                    _selectedStatus = newStatus ?? 'pending';
                  });
                  updateOrderStatus(_selectedStatus);
                },
                items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              const SizedBox(width: 10),

              // Pack Med Button
              TextButton(
                child: const Text("Pack Med"),
                onPressed: () => _showOrderDialog(context),
              ),

              const SizedBox(width: 10),

              // Direct Call Button
              IconButton(
                icon: const Icon(Icons.call),
                tooltip: "Call Patient",
                onPressed: () async {
                  final phone = widget.phone;
                  if (phone != null && phone.isNotEmpty) {
                    final Uri url = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch phone dialer')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number not available')),
                    );
                  }
                },
              ),

                        // More Icon
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'clear') {
                    // Show confirmation dialog
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Chat'),
                        content: const Text('Are you sure you want to delete all messages?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    // If user confirmed, delete messages
                    if (shouldDelete == true) {
                      final conversationId = widget.conversationId;
                      final messagesRef = FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(conversationId)
                          .collection('messages');

                      final batch = FirebaseFirestore.instance.batch();
                      final snapshot = await messagesRef.get();

                      for (final doc in snapshot.docs) {
                        batch.delete(doc.reference);
                      }

                      await batch.commit();
                      print('All messages deleted');
                    }
                  } else {
                    // Coming soon actions
                    print('$value is coming soon');
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Text('Clear Chat'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'soon1',
                    child: Text('Coming Soon'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'soon2',
                    child: Text('Coming Soon'),
                  ),
                ],
              ),

              if (isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete,color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Messages"),
                        content: const Text("Are you sure you want to delete the all messages?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await deleteSelectedMessages();
                    }
                  },
                ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final messageId = msg.id;
                    final type = data['type'] ?? 'text';
                    final text = data['text'] ?? '';
                    final fileUrl = data['fileUrl'] ?? data['imageUrl'] ?? '';
                    final isUser = data['isUser'] ?? false;
                    final isMe = !isUser;

                    Widget messageContent;

                    if (type == 'image' && fileUrl.isNotEmpty) {
                      messageContent = ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(fileUrl, width: 200, height: 200, fit: BoxFit.cover),
                      );
                    } else if (type == 'voice' && fileUrl.isNotEmpty) {
                      messageContent = VoicePlayerWidget(filePath: fileUrl, isUser: isUser);
                    } else {
                      messageContent = ChatBubble(text: text, isMe: isMe);
                    }

                    bool isSelected = selectedMessageIds.contains(messageId);

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          if (isSelected) {
                            selectedMessageIds.remove(messageId);
                          } else {
                            selectedMessageIds.add(messageId);
                          }
                        });
                      },
                      onTap: () {
                        if (isSelectionMode) {
                          setState(() {
                            isSelected ? selectedMessageIds.remove(messageId) : selectedMessageIds.add(messageId);
                          });
                        }
                      },
                      child: Container(
                        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: messageContent,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        MessageInputBar(
          onSend: (text) => sendMessage(text),
          onImageSend: (imageUrl) => sendImageMessage(imageUrl),
        ),
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
        color: isMe ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
      ),
    );
  }
}

class VoicePlayerWidget extends StatefulWidget {
  final String filePath; // Firebase Storage URL
  final bool isUser;

  const VoicePlayerWidget({
    super.key,
    required this.filePath,
    this.isUser = true,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  final PlayerController _controller = PlayerController();
  final just_audio.AudioPlayer _fallbackPlayer = just_audio.AudioPlayer();
  bool _isPlaying = false;
  bool _useFallback = false;
  double _waveformWidth = 100;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _controller.onCurrentDurationChanged.listen((_) {
      if (mounted) setState(() {});
    });
    _fallbackPlayer.positionStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeAudio() async {
    try {
      // Try audio_waveforms directly from Firebase URL
      try {
        await _controller.preparePlayer(
          path: widget.filePath,
          shouldExtractWaveform: true,
        );
      } catch (e) {
        debugPrint('Waveform extraction failed: $e');
        setState(() => _useFallback = true);
      }

      // Get duration using just_audio
      final duration = await _fallbackPlayer.setUrl(widget.filePath);
      if (duration != null && mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = screenWidth * 0.4;
        setState(() {
          _waveformWidth = (duration.inSeconds * 35.0).clamp(120.0, maxWidth.toDouble());
          _totalDuration = duration;
        });
      }
    } catch (e) {
      debugPrint('Error initializing voice player: $e');
      setState(() => _useFallback = true);
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_useFallback) {
        if (_isPlaying) {
          await _fallbackPlayer.pause();
        } else {
          await _fallbackPlayer.play();
        }
      } else {
        if (_isPlaying) {
          await _controller.pausePlayer();
        } else {
          await _controller.startPlayer();
        }
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      debugPrint('Error playing voice: $e');
      setState(() => _useFallback = true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.stopPlayer();
    _controller.dispose();
    _fallbackPlayer.stop();
    _fallbackPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isUser ? Colors.white : Colors.black;
    final textColor = widget.isUser ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isUser ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Iconsax.pause : Iconsax.play,
              color: iconColor,
              size: 20,
            ),
            onPressed: _togglePlay,
            tooltip: _isPlaying ? 'Pause' : 'Play',
          ),
          Flexible(
            child: _useFallback
                ? Text(
              'Playing voice...',
              style: TextStyle(color: textColor, fontSize: 12),
            )
                : AudioFileWaveforms(
              size: Size(_waveformWidth, 30),
              playerController: _controller,
              enableSeekGesture: true,
              waveformType: WaveformType.long,
              playerWaveStyle: PlayerWaveStyle(
                fixedWaveColor: iconColor.withOpacity(0.6),
                liveWaveColor:
                widget.isUser ? Colors.white : const Color(0xff8bc440),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_totalDuration),
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}



