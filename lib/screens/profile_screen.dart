import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/imgbb_service.dart'; // Asegúrate de que esta ruta es correcta

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = AuthService().currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController(); // Control de Estado/Info
  final ImgbbService _imgbbService = ImgbbService();

  bool _isUploading = false;
  String? _displayImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Cargar datos existentes desde Firestore
  Future<void> _loadUserProfile() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['displayName'] ?? currentUser!.displayName ?? "";
        _aboutController.text = data['about'] ?? "¡Hola! Estoy usando la App."; // Valor por defecto
        _displayImage = data['photoURL'] ?? currentUser!.photoURL;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);

      try {
        final Uint8List imageBytes = await image.readAsBytes();
        String? newPhotoUrl = await _imgbbService.uploadImage(imageBytes);

        if (newPhotoUrl != null) {
          setState(() {
            _displayImage = newPhotoUrl;
          });
          // Guardamos automáticamente al subir la foto
          await _saveToFirestore(photoOnly: true); 
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto de perfil actualizada")));
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        if(mounted) setState(() => _isUploading = false);
      }
    }
  }

  // Función unificada para guardar
  Future<void> _saveProfile() async {
    await _saveToFirestore();
    if(mounted) Navigator.pop(context);
  }

  Future<void> _saveToFirestore({bool photoOnly = false}) async {
    if (currentUser == null) return;
    if (!photoOnly) setState(() => _isUploading = true);

    try {
      Map<String, dynamic> dataToUpdate = {};

      if (!photoOnly) {
        String newName = _nameController.text.trim();
        String newAbout = _aboutController.text.trim();
        if (newName.isEmpty) newName = "Usuario";
        
        await currentUser!.updateDisplayName(newName);
        dataToUpdate['displayName'] = newName;
        dataToUpdate['about'] = newAbout;
        dataToUpdate['email'] = currentUser!.email; // Aseguramos el email
      }

      if (_displayImage != null) {
        await currentUser!.updatePhotoURL(_displayImage);
        dataToUpdate['photoURL'] = _displayImage;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(dataToUpdate, SetOptions(merge: true));

    } catch (e) {
      print("Error guardando perfil: $e");
    } finally {
      if (!photoOnly && mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- SECCIÓN FOTO ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _displayImage != null ? NetworkImage(_displayImage!) : null,
                    child: _displayImage == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF25D366),
                      radius: 24,
                      child: IconButton(
                        icon: _isUploading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- SECCIÓN NOMBRE ---
            _buildSectionHeader(Icons.person, "Nombre"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: "Tu nombre",
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.grey, size: 20),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Este no es tu nombre de usuario ni un PIN. Este nombre será visible para tus contactos.", 
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),

            // --- SECCIÓN INFO (ESTADO) ---
            _buildSectionHeader(Icons.info_outline, "Info."),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aboutController,
                      decoration: const InputDecoration(
                        hintText: "Disponible",
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.grey, size: 20),
                ],
              ),
            ),

            // --- SECCIÓN EMAIL ---
            _buildSectionHeader(Icons.email, "Correo"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.white,
              width: double.infinity,
              child: Text(
                currentUser?.email ?? "",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),
            
            // Botón Guardar Flotante (estilo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF075E54), size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}