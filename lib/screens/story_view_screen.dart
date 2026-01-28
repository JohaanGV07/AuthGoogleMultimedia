import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_auth/services/story_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../services/auth_service.dart';

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({super.key});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryService _storyService = StoryService();
  final currentUser = AuthService().currentUser;
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final Uint8List bytes = await image.readAsBytes();
        await _storyService.postStory(
          uid: currentUser!.uid,
          username: currentUser!.displayName ?? "Usuario",
          userPhoto: currentUser!.photoURL ?? "",
          imageFile: bytes,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Historia subida")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Botón para subir historia
          ListTile(
            leading: Stack(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(currentUser?.photoURL ?? "")),
                const Positioned(bottom: 0, right: 0, child: Icon(Icons.add_circle, color: Colors.green, size: 20)),
              ],
            ),
            title: const Text("Mi Estado"),
            subtitle: const Text("Toca para añadir una actualización"),
            onTap: _isUploading ? null : _uploadStory,
          ),
          if (_isUploading) const LinearProgressIndicator(),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Actualizaciones recientes", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          
          // Lista de historias
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _storyService.getActiveStories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final stories = snapshot.data!.docs;

                if (stories.isEmpty) return const Center(child: Text("No hay historias recientes"));

                return ListView.builder(
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final data = stories[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2), // Borde de historia
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(data['userPhoto'] ?? ""),
                        ),
                      ),
                      title: Text(data['username']),
                      subtitle: Text("Hace un momento"), // Podrías calcular la diferencia de tiempo
                      onTap: () {
                        // Diálogo simple para ver la foto
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(data['imageUrl']),
                                if(data['caption'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(data['caption']),
                                  )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}