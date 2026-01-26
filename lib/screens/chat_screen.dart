import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; 
import '../services/auth_service.dart';

// 1. CORRECCIÓN DE IMPORT: Apuntamos a la carpeta correcta
// Si te da error, asegúrate de que 'imgbb_service.dart' está en 'lib/core/services/'
// Si lo tienes en 'lib/services/', cambia 'core/services' por 'services'
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
  
  // Instancia del servicio Imgbb
  final ImgbbService _imgbbService = ImgbbService(); 

  bool _isShowEmoji = false;
  bool _isUploading = false;

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

  String get chatId {
    List<String> ids = [currentUser!.uid, widget.receiverId];
    ids.sort();
    return ids.join("_");
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
  }

  // --- FUNCIÓN PARA SUBIR IMAGEN ---
  Future<void> _sendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

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
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverName,
                style: const TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis),
              ),
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
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg = snapshot.data!.docs[index];
                    final isMe = msg['senderId'] == currentUser!.uid;
                    final type = msg['type'] ?? 'text';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(5),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1))
                          ],
                        ),
                        child: type == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  msg['imageUrl'] ?? '',
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                        height: 150, 
                                        width: 150, 
                                        alignment: Alignment.center,
                                        child: const CircularProgressIndicator()
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
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
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Row(
                      children: [
                        // --- BOTÓN EMOJIS (NUEVO) ---
                        IconButton(
                          icon: Icon(
                            _isShowEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isShowEmoji = !_isShowEmoji;
                              if (_isShowEmoji) {
                                _focusNode.unfocus(); // Ocultar teclado
                              } else {
                                _focusNode.requestFocus(); // Mostrar teclado
                              }
                            });
                          },
                        ),
                        
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: "Mensaje",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ),
                        
                        // Botón Cámara (Envía imagen)
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.grey),
                          onPressed: _sendImage,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

          // --- SELECTOR DE EMOJIS (NUEVO) ---
          if (_isShowEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text = _messageController.text + emoji.emoji;
                },
                config: Config(
                  // Configuración estándar compatible
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.RECENT,
                    indicatorColor: Color(0xFF075E54),
                    iconColorSelected: Color(0xFF075E54),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}