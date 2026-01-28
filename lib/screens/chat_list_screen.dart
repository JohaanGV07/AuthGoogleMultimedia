import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

// Importamos las pantallas locales (misma carpeta)
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'create_group_screen.dart'; // <--- Este es el archivo que acabamos de crear
import 'group_chat_screen.dart';
import 'story_view_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("WhatsApp Clone", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "CHATS"),
              Tab(text: "GRUPOS"),
              Tab(text: "ESTADOS"),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                } else if (value == 'logout') {
                  AuthService().signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'profile', child: Text("Mi Perfil")),
                const PopupMenuItem(value: 'logout', child: Text("Cerrar Sesión")),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildIndividualChats(context, currentUser),
            _buildGroups(context, currentUser),
            const StoryViewScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Acción para crear grupo
            // Aquí llamamos a la pantalla. Si da error, asegúrate de haber creado el archivo 'create_group_screen.dart'
            Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGroupScreen()));
          },
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.group_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildIndividualChats(BuildContext context, dynamic currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            if (userData['uid'] == currentUser?.uid) return const SizedBox.shrink();

            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(userData['photoURL'] ?? "https://via.placeholder.com/150"),
              ),
              title: Text(userData['displayName'] ?? "Usuario"),
              subtitle: Text(userData['email'] ?? ""),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: userData['uid'],
                      receiverName: userData['displayName'] ?? "Usuario",
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroups(BuildContext context, dynamic currentUser) {
    final GroupService groupService = GroupService();
    return StreamBuilder<QuerySnapshot>(
      stream: groupService.getUserGroups(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!.docs;

        if (groups.isEmpty) {
          return const Center(child: Text("No estás en ningún grupo."));
        }

        return ListView.separated(
          itemCount: groups.length,
          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(group['photoUrl'] ?? "https://via.placeholder.com/150"),
              ),
              title: Text(group['name']),
              subtitle: Text(group['lastMessage'] ?? "Grupo nuevo"),
              trailing: Text(
                _formatTimestamp(group['lastMessageTime']),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      groupId: groups[index].id,
                      groupName: group['name'],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";
  }
}