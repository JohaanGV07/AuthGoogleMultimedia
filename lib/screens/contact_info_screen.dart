import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactInfoScreen extends StatelessWidget {
  final String userId;

  const ContactInfoScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Info. del contacto"), // Estilo WhatsApp: sin color sólido a veces, pero mantenemos tu tema
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['displayName'] ?? "Usuario";
          final email = data['email'] ?? "No disponible";
          final photo = data['photoURL'] ?? "https://via.placeholder.com/150";
          final about = data['about'] ?? "¡Hola! Estoy usando CoffeExpress.";

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Foto gigante
                CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(photo),
                  backgroundColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                // Sección de "Info" (Estado)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Info. y número de teléfono", 
                          style: TextStyle(color: const Color(0xFF075E54), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(about, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 5),
                      Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)), // Ponemos email en vez de tlf
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Botones de acción (Bloquear, etc. - Solo visuales por ahora)
                _buildActionTile(Icons.block, "Bloquear", Colors.red),
                _buildActionTile(Icons.thumb_down, "Reportar contacto", Colors.red),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String text, Color color) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(color: color, fontSize: 16)),
        onTap: () {
          // Lógica futura
        },
      ),
    );
  }
}