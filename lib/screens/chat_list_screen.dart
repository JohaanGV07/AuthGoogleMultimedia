import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      // Color de fondo blanco limpio
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chats", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF075E54), // Verde WhatsApp oscuro
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return const Center(child: Text("Error al cargar contactos"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay contactos disponibles."));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80), // Línea separadora
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              
              // No mostrarse a uno mismo
              if (userData['uid'] == currentUser?.uid) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 28, // Avatar más grande
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: NetworkImage(userData['photoURL'] ?? "https://via.placeholder.com/150"),
                ),
                title: Text(
                  userData['displayName'] ?? "Usuario",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    userData['email'] ?? "",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Fecha simulada para el estilo (puedes mejorar esto con datos reales luego)
                trailing: Text(
                  "Ayer", 
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        receiverId: userData['uid'],
                        receiverName: userData['displayName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}