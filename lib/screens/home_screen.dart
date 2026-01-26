import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'chat_list_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() {
        _role = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            const SizedBox(height: 20),
            Text(
              "Hola, ${user?.displayName}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Chip(
              label: Text("Rol: $_role"),
              backgroundColor: _role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
            ),
            const SizedBox(height: 40),

            // Botón de Chat (Para todos)
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text("Ir al Chat Global"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            // Botón de Admin (Solo si eres admin)
            if (_role == 'admin')
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Admin Dashboard"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}