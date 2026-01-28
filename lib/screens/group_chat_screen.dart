import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_auth/services/group_service.dart';
import 'package:google_auth/services/imgbb_service.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Importante

import '../services/auth_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GroupService _groupService = GroupService();
  final ImgbbService _imgbbService = ImgbbService();
  final currentUser = AuthService().currentUser;
  final FocusNode _focusNode = FocusNode(); // Para el teclado

  bool _isUploading = false;
  bool _isShowEmoji = false; // Estado emojis

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isShowEmoji = false;
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _groupService.sendGroupMessage(
      widget.groupId,
      currentUser!.uid,
      currentUser!.displayName ?? "Usuario",
      _messageController.text.trim(),
      type: 'text',
    );
    _messageController.clear();
  }

  Future<void> _sendImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() => _isUploading = true);

      try {
        final imageBytes = await image.readAsBytes();
        String? imageUrl = await _imgbbService.uploadImage(imageBytes);

        if (imageUrl != null) {
          await _groupService.sendGroupMessage(
            widget.groupId,
            currentUser!.uid,
            currentUser!.displayName ?? "Usuario",
            '📷 Imagen',
            type: 'image',
            imageUrl: imageUrl,
          );
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir imagen")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _groupService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser!.uid;
                    final type = msg['type'] ?? 'text';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(5),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 1, offset: const Offset(0, 1))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 5, top: 5, right: 5),
                                child: Text(msg['senderName'] ?? "Anon", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            
                            if (type == 'image')
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    msg['imageUrl'] ?? '',
                                    loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(height: 150, width: 150, alignment: Alignment.center, child: const CircularProgressIndicator()),
                                    errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(msg['text'] ?? "", style: const TextStyle(fontSize: 16)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          if (_isUploading) const LinearProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        // BOTÓN EMOJI
                        IconButton(
                          icon: Icon(
                             _isShowEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                             color: Colors.grey[600]
                          ),
                          onPressed: () {
                            setState(() {
                              _isShowEmoji = !_isShowEmoji;
                              if (_isShowEmoji) {
                                _focusNode.unfocus();
                              } else {
                                _focusNode.requestFocus();
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: "Escribir en el grupo...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 5),
                            ),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () => _sendImage(ImageSource.gallery)),
                        IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _sendImage(ImageSource.camera)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF075E54),
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                )
              ],
            ),
          ),

          // SELECTOR EMOJIS
          if (_isShowEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text = _messageController.text + emoji.emoji;
                },
                config: Config(
                  emojiViewConfig: const EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                    backgroundColor: Color(0xFFF2F2F2),
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.RECENT,
                    indicatorColor: Color(0xFF075E54),
                    iconColorSelected: Color(0xFF075E54),
                    backspaceColor: Color(0xFF075E54),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}