import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

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
      'timestamp': FieldValue.serverTimestamp(),
      'senderName': currentUser!.displayName,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // Fondo beige clásico
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
        backgroundColor: const Color(0xFF075E54), // Verde oscuro
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
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

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white, // Verde claro para mí, blanco para otro
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['text'],
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            // Hora simulada pequeña
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "12:00", // Aquí podrías formatear el timestamp real
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: isMe ? Colors.grey[600] : Colors.grey[500],
                                ),
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
          
          // --- BARRA DE ESCRITURA ---
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
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Mensaje",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.grey),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF00897B), // Verde botón
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}