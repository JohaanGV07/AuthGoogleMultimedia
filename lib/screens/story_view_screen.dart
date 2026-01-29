import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/story_service.dart';
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
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estado subido")));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if(mounted) setState(() => _isUploading = false);
      }
    }
  }

  // Función para abrir el visor de historias a pantalla completa
  void _openStoryViewer(List<QueryDocumentSnapshot> userStories) {
    showDialog(
      context: context,
      builder: (_) => _StoryFullScreenViewer(stories: userStories),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sección de "Mi Estado"
          ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(currentUser?.photoURL ?? "https://via.placeholder.com/150"),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add_circle, color: Color(0xFF25D366), size: 20),
                  ),
                ),
              ],
            ),
            title: const Text("Mi estado", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Toca para añadir una actualización"),
            onTap: _isUploading ? null : _uploadStory,
          ),
          if (_isUploading) const LinearProgressIndicator(),
          
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Actualizaciones recientes", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // Lista de historias AGRUPADAS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _storyService.getActiveStories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final allStories = snapshot.data!.docs;
                if (allStories.isEmpty) return const Center(child: Text("No hay estados recientes"));

                // --- LÓGICA DE AGRUPACIÓN ---
                // Mapa: { 'uid_usuario': [Historia1, Historia2, ...] }
                Map<String, List<QueryDocumentSnapshot>> groupedStories = {};
                
                for (var doc in allStories) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = data['uid'];
                  
                  // No mostramos mis propias historias en la lista de "recientes" (opcional)
                  if (uid == currentUser?.uid) continue;

                  if (!groupedStories.containsKey(uid)) {
                    groupedStories[uid] = [];
                  }
                  groupedStories[uid]!.add(doc);
                }

                if (groupedStories.isEmpty) return const Center(child: Text("No hay actualizaciones de amigos"));

                final userIds = groupedStories.keys.toList();

                return ListView.separated(
                  itemCount: userIds.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final uid = userIds[index];
                    final stories = groupedStories[uid]!;
                    final firstStoryData = stories.last.data() as Map<String, dynamic>; // Mostramos la última subida
                    final int count = stories.length;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Borde verde si hay historias nuevas (simulado siempre verde aquí)
                          border: Border.all(color: const Color(0xFF25D366), width: 3),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(firstStoryData['userPhoto'] ?? ""),
                        ),
                      ),
                      title: Text(firstStoryData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Hace un momento • $count nuevas"),
                      onTap: () => _openStoryViewer(stories),
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

// Widget Interno: Visor de Historias a Pantalla Completa
class _StoryFullScreenViewer extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;
  const _StoryFullScreenViewer({required this.stories});

  @override
  State<_StoryFullScreenViewer> createState() => _StoryFullScreenViewerState();
}

class _StoryFullScreenViewerState extends State<_StoryFullScreenViewer> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final data = widget.stories[index].data() as Map<String, dynamic>;
              return Center(
                child: Image.network(
                  data['imageUrl'],
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) => progress == null 
                      ? child 
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              );
            },
          ),
          
          // Barra superior (Progreso y Usuario)
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Indicadores de progreso (barritas)
                Row(
                  children: List.generate(widget.stories.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentIndex ? Colors.white : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // Info del usuario
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage((widget.stories[0].data() as Map<String, dynamic>)['userPhoto']),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      (widget.stories[0].data() as Map<String, dynamic>)['username'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ],
            ),
          ),
          
          // Caption (Texto de la historia)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              (widget.stories[_currentIndex].data() as Map<String, dynamic>)['caption'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
            ),
          )
        ],
      ),
    );
  }
}