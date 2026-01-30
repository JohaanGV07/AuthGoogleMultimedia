import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; 
import 'package:intl/intl.dart'; 

import '../services/auth_service.dart';
import '../services/imgbb_service.dart';
import 'contact_info_screen.dart';
import 'forward_selector_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  final ImgbbService _imgbbService = ImgbbService(); 
  
  bool _isUploading = false;
  bool _isShowEmoji = false;
  final FocusNode _focusNode = FocusNode();

  String get chatId {
    List<String> ids = [currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _isShowEmoji = false);
    });
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'text': text ?? '',
      'imageUrl': imageUrl,
      'type': imageUrl != null ? 'image' : 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'senderName': currentUser!.displayName,
      'isRead': false,
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
        final bytes = await image.readAsBytes();
        String? url = await _imgbbService.uploadImage(bytes);
        if (url != null) _sendMessage(text: "📷 Imagen", imageUrl: url);
      } finally {
        if(mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), 
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactInfoScreen(userId: widget.receiverId))),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.receiverName, style: const TextStyle(fontSize: 18.5))),
            ],
          ),
        ),
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

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser!.uid;
                    
                    // --- CORRECCIÓN LÓGICA DE LECTURA ---
                    // Solo marco como leído si NO soy yo (es decir, lo recibí yo) y aún no está leído.
                    if (!isMe && (msg['isRead'] == null || msg['isRead'] == false)) {
                       // Usamos microtask para actualizar la DB sin bloquear la UI
                       Future.microtask(() => doc.reference.update({'isRead': true}));
                    }

                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          
          if (_isUploading) const LinearProgressIndicator(color: Color(0xFF075E54)),
          _buildInputArea(),
          if (_isShowEmoji) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final timestamp = msg['timestamp'] as Timestamp?;
    final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : "...";
    final isRead = msg['isRead'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(5),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 1, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg['type'] == 'image')
               ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(msg['imageUrl'] ?? ''))
            else
               Padding(
                 padding: const EdgeInsets.only(left: 8, right: 25, top: 5, bottom: 5),
                 child: Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
               ),
            
            // --- HORA Y TICKS ---
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  // SOLO mostramos los ticks si el mensaje es MÍO
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all, 
                      size: 16, 
                      // Azul si está leído, Gris si no
                      color: isRead ? Colors.blue : Colors.grey
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (El resto de _buildInputArea y _buildEmojiPicker se queda igual que en la versión anterior)
  // ...
    Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isShowEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                    onPressed: () { setState(() { _isShowEmoji = !_isShowEmoji; if(_isShowEmoji) _focusNode.unfocus(); else _focusNode.requestFocus(); }); },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 6,
                      decoration: const InputDecoration(hintText: "Mensaje", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 5)),
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
            radius: 24,
            backgroundColor: const Color(0xFF00897B),
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: () => _sendMessage(text: _messageController.text)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => _messageController.text += emoji.emoji,
        config: const Config(emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 32, backgroundColor: Color(0xFFF2F2F2))),
      ),
    );
  }
}