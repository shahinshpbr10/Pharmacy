import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class MessageInputBar extends StatefulWidget {
  final void Function(String message) onSend;
  final void Function(String imageUrl)? onImageSend;

  const MessageInputBar({super.key, required this.onSend, this.onImageSend});

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final url = await _uploadFile(picked);
      if (url != null && widget.onImageSend != null) {
        widget.onImageSend!(url);
      }
    }
  }

  Future<String?> _uploadFile(XFile file) async {
    try {
      final fileName = path.basename(file.path);
      final ref = FirebaseStorage.instance.ref().child('chat_files/$fileName');
      final uploadTask = ref.putData(await file.readAsBytes());
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _pickImage(source: ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _pickImage(source: ImageSource.camera),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
