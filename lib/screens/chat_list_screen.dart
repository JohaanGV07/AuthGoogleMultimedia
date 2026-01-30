import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart'; // Asegúrate de la ruta

// Importamos las pantallas locales
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'story_view_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = AuthService().currentUser;

  // Filtro básico visual
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    // CAMBIO: Ahora son 3 pestañas, no 4 ni 3 con llamadas
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "WhatsApp Clone",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new_group') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'logout') {
                AuthService().signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text("Nuevo grupo"),
              ),
              const PopupMenuItem(value: 'settings', child: Text("Ajustes")),
              const PopupMenuItem(
                value: 'logout',
                child: Text("Cerrar sesión"),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ), // Letra un poco más pequeña
          tabs: const [
            Tab(text: "CHATS"),
            Tab(text: "GRUPOS"),
            Tab(text: "ESTADOS"), // Quitamos LLAMADAS
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: CHATS
          Column(
            children: [
              _buildFilterBar(),
              Expanded(child: _buildChatList()),
            ],
          ),

          // PESTAÑA 2: GRUPOS
          _buildGroupsList(),

          // PESTAÑA 3: ESTADOS
          const StoryViewScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lógica simple para el botón flotante según la pestaña
          if (_tabController.index == 0) {
            // En chats, podría ir a contactos, aquí reutilizamos crear grupo o perfil
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Seleccionar contacto")),
            );
          } else if (_tabController.index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            );
          }
        },
        backgroundColor: const Color(0xFF00897B),
        child: Icon(
          _tabController.index == 1 ? Icons.group_add : Icons.message,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip("Todos", 'all'),
          const SizedBox(width: 8),
          _buildFilterChip("No leídos", 'unread'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE7FFDB) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF075E54).withOpacity(0.3))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF075E54) : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Lista de Chats Individuales
  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (ctx, i) =>
              const Divider(height: 1, indent: 80), // Separador sutil
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            if (userData['uid'] == currentUser?.uid)
              return const SizedBox.shrink();

            // Usamos ui-avatars como fallback más estable que placeholder.com
            final String photoUrl =
                userData['photoURL'] ??
                "https://ui-avatars.com/api/?name=${userData['displayName']}&background=random";

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ), // Menos padding vertical
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(photoUrl),
                onBackgroundImageError: (_, __) {
                  // Si falla la imagen, no crashea, solo muestra el color de fondo
                },
              ),
              title: Text(
                userData['displayName'] ?? "Usuario",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                userData['about'] ??
                    userData['email'] ??
                    "¡Hola! Estoy usando la App.",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              // ARREGLO DEL OVERFLOW: Usamos MainAxisSize.min
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // <--- ESTO ARREGLA EL MENSAJITO ROJO
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "18:30",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ), // Hora simulada
                  // INDICADOR DE NO LEÍDOS REAL
                  _buildUnreadBadge(currentUser!.uid, userData['uid']),
                ],
              ),
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

  // --- Widget para contar mensajes no leídos ---
  Widget _buildUnreadBadge(String currentUserId, String peerId) {
    List<String> ids = [currentUserId, peerId];
    ids.sort();
    String chatId = ids.join("_");

    return StreamBuilder<QuerySnapshot>(
      // Escuchamos mensajes del chat donde el remitente es EL OTRO y no están leídos
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: peerId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Si no hay mensajes no leídos, devolvemos un widget vacío (invisible)
          return const SizedBox(width: 10, height: 10);
        }

        final int count = snapshot.data!.docs.length;

        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFF25D366),
            shape: BoxShape.circle,
          ),
          child: Text(
            count > 9 ? "9+" : count.toString(), // Si son más de 9, ponemos 9+
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // Lista de Grupos
  Widget _buildGroupsList() {
    final GroupService groupService = GroupService();
    return StreamBuilder<QuerySnapshot>(
      stream: groupService.getUserGroups(currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!.docs;
        if (groups.isEmpty)
          return const Center(child: Text("No tienes grupos."));

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(
                  group['photoUrl'] ??
                      "https://ui-avatars.com/api/?name=${group['name']}",
                ),
              ),
              title: Text(
                group['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(group['lastMessage'] ?? ""),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    groupId: groups[index].id,
                    groupName: group['name'],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
