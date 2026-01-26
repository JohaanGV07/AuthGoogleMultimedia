import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _deleteUser(String userId) {
    FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  void _toggleAdmin(String userId, String currentRole) {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    FirebaseFirestore.instance.collection('users').doc(userId).update({'role': newRole});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['photoURL'] ?? "https://via.placeholder.com/150"),
                  ),
                  title: Text(data['displayName'] ?? "Usuario"),
                  subtitle: Text("Rol: ${data['role'] ?? 'user'} | ${data['email']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para cambiar Rol
                      IconButton(
                        icon: Icon(
                          data['role'] == 'admin' ? Icons.security : Icons.person,
                          color: data['role'] == 'admin' ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleAdmin(user.id, data['role'] ?? 'user'),
                        tooltip: "Cambiar Rol",
                      ),
                      // Botón para Eliminar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user.id),
                        tooltip: "Eliminar Usuario",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}