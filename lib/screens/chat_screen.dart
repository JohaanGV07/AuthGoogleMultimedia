import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // Importante
import '../services/auth_service.dart';
import '../services/imgbb_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = AuthService().currentUser;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  final ImgbbService _imgbbService = ImgbbService(); 

  bool _isUploading = false;
  bool _isShowEmoji = false; // Estado para mostrar/ocultar emojis

  @override
  void initState() {
    super.initState();
    // Si el teclado se abre, ocultamos el panel de emojis
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isShowEmoji = false;
        });
      }
    });
  }

  String get chatId {
    List<String> ids = [currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'text': _messageController.text.trim(),
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'senderName': currentUser!.displayName,
    });

    _messageController.clear();
    _scrollToBottom();
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
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .add({
            'senderId': currentUser!.uid,
            'imageUrl': imageUrl,
            'text': '📷 Imagen',
            'type': 'image',
            'timestamp': FieldValue.serverTimestamp(),
            'senderName': currentUser!.displayName,
          });
          _scrollToBottom();
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir la imagen")));
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
        titleSpacing: 0,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back),
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
              style: const TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg = snapshot.data!.docs[index];
                    final isMe = msg['senderId'] == currentUser!.uid;
                    final type = msg['type'] ?? 'text';
                    final timestamp = msg['timestamp'] as Timestamp?;
                    
                    final time = timestamp != null 
                        ? "${timestamp.toDate().hour.toString().padLeft(2,'0')}:${timestamp.toDate().minute.toString().padLeft(2,'0')}" 
                        : "";

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(5),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 2, offset: const Offset(1, 1))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (type == 'image')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    msg['imageUrl'] ?? '',
                                    loadingBuilder: (ctx, child, progress) => progress == null ? child : Container(height: 150, width: 150, color: Colors.grey[200], alignment: Alignment.center, child: const CircularProgressIndicator()),
                                    errorBuilder: (ctx, _, __) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                )
                            else
                              Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 20),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ),
                            
                            Padding(
                              padding: const EdgeInsets.only(right: 5, bottom: 2, left: 5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.done_all, size: 16, color: Colors.blue),
                                  ]
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          if (_isUploading) const LinearProgressIndicator(color: Color(0xFF075E54)),

          // --- BARRA DE ESCRITURA ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                         BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 2, offset: const Offset(0, 1))
                      ]
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                            minLines: 1,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: "Mensaje",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                          onPressed: () => _sendImage(ImageSource.gallery),
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                          onPressed: () => _sendImage(ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF00897B),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),

          // --- SELECTOR DE EMOJIS ---
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