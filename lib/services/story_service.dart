import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/imgbb_service.dart';
import 'dart:typed_data';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImgbbService _imgbbService = ImgbbService();

  // Subir una historia
  Future<void> postStory({
    required String uid,
    required String username,
    required String userPhoto,
    required Uint8List imageFile,
    String caption = '',
  }) async {
    // 1. Subir imagen
    final imageUrl = await _imgbbService.uploadImage(imageFile);
    if (imageUrl == null) throw Exception("Error al subir imagen");

    // 2. Calcular expiración (24h desde ahora)
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    // 3. Guardar en Firestore
    await _firestore.collection('stories').add({
      'uid': uid,
      'username': username,
      'userPhoto': userPhoto,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  // Obtener historias activas (no expiradas)
  Stream<QuerySnapshot> getActiveStories() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false) // Las que van a expirar pronto primero
        .snapshots();
  }
}