import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';

import 'package:google_auth/services/imgbb_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImgbbService _imgbbService = ImgbbService();

  // Crear un grupo
  Future<void> createGroup(String groupName, List<String> memberIds, String adminId, Uint8List? imageFile) async {
    String groupPhotoUrl = "https://via.placeholder.com/150"; // Imagen por defecto

    // 1. Subir imagen si existe
    if (imageFile != null) {
      final url = await _imgbbService.uploadImage(imageFile);
      if (url != null) groupPhotoUrl = url;
    }

    // 2. Crear documento del grupo
    // Añadimos al admin a la lista de miembros
    if (!memberIds.contains(adminId)) {
      memberIds.add(adminId);
    }

    await _firestore.collection('groups').add({
      'name': groupName,
      'photoUrl': groupPhotoUrl,
      'adminId': adminId,
      'members': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Grupo creado',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Obtener grupos del usuario
  Stream<QuerySnapshot> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Enviar mensaje a grupo
  Future<void> sendGroupMessage(String groupId, String senderId, String senderName, String text, {String type = 'text', String? imageUrl}) async {
    final timestamp = FieldValue.serverTimestamp();

    await _firestore.collection('groups').doc(groupId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName, // Importante en grupos para saber quién habla
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    });

    // Actualizar último mensaje del grupo
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': type == 'image' ? '📷 Imagen' : '$senderName: $text',
      'lastMessageTime': timestamp,
    });
  }

  // Stream de mensajes del grupo
  Stream<QuerySnapshot> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}