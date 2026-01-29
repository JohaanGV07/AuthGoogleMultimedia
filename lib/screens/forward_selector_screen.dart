import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_auth/services/auth_service.dart';

class ForwardSelectorScreen extends StatelessWidget {
  const ForwardSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reenviar a..."),
        backgroundColor: const Color(0xFF075E54),
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
              final userData = users[index].data() as Map<String, dynamic>;
              if (userData['uid'] == currentUser?.uid) return const SizedBox.shrink();

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userData['photoURL'] ?? "https://via.placeholder.com/150"),
                ),
                title: Text(userData['displayName'] ?? "Usuario"),
                onTap: () {
                  // Devolvemos los datos del usuario seleccionado
                  Navigator.pop(context, userData);
                },
              );
            },
          );
        },
      ),
    );
  }
}