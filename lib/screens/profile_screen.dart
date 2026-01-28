import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
// Asegúrate de que la ruta a tu servicio Imgbb sea correcta
import '../services/imgbb_service.dart'; 
// import '../core/services/imgbb_service.dart'; // Usa esta si lo guardaste en core

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = AuthService().currentUser;
  final TextEditingController _nameController = TextEditingController();
  final ImgbbService _imgbbService = ImgbbService();

  bool _isUploading = false;
  String? _displayImage;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _nameController.text = currentUser!.displayName ?? "";
      _displayImage = currentUser!.photoURL;
    }
  }

  // Función para seleccionar y subir nueva foto
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);

      try {
        final Uint8List imageBytes = await image.readAsBytes();
        
        // 1. Subir a Imgbb
        String? newPhotoUrl = await _imgbbService.uploadImage(imageBytes);

        if (newPhotoUrl != null) {
          setState(() {
            _displayImage = newPhotoUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Imagen subida. No olvides guardar cambios.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al subir imagen a Imgbb")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  // Guardar cambios en Firebase (Auth y Firestore)
  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    
    setState(() => _isUploading = true);

    try {
      String newName = _nameController.text.trim();
      if (newName.isEmpty) newName = "Usuario";

      // 1. Actualizar perfil de Firebase Auth (para la sesión actual)
      await currentUser!.updateDisplayName(newName);
      if (_displayImage != null) {
        await currentUser!.updatePhotoURL(_displayImage);
      }

      // 2. Actualizar documento en Firestore (para que otros usuarios lo vean)
      Map<String, dynamic> dataToUpdate = {
        'displayName': newName,
      };
      if (_displayImage != null) {
        dataToUpdate['photoURL'] = _displayImage;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Perfil actualizado con éxito!")),
        );
        Navigator.pop(context); // Volver atrás
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar perfil: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- AVATAR CON BOTÓN DE CAMBIO ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _displayImage != null 
                        ? NetworkImage(_displayImage!) 
                        : null,
                    child: _displayImage == null 
                        ? const Icon(Icons.person, size: 70, color: Colors.white) 
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF25D366),
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickAndUploadImage,
                        tooltip: "Cambiar foto",
                      ),
                    ),
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- CAMPO DE NOMBRE ---
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre de usuario",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 10),
            
            // Mostrar Email (Solo lectura)
            ListTile(
              leading: const Icon(Icons.email, color: Colors.grey),
              title: Text(currentUser?.email ?? ""),
              subtitle: const Text("Este correo no se puede cambiar"),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 30),

            // --- BOTÓN GUARDAR ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.save),
                label: Text(
                  _isUploading ? "Guardando..." : "Guardar Cambios",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}