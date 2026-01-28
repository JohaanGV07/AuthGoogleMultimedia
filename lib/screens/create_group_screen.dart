import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/auth_service.dart';
// Asegúrate de que GroupService existe en lib/services/group_service.dart
import '../services/group_service.dart'; 

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final GroupService _groupService = GroupService();
  final currentUser = AuthService().currentUser;

  List<String> _selectedUserIds = [];
  Uint8List? _groupImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _groupImage = bytes);
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pon nombre y elige miembros")));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _groupService.createGroup(
        _nameController.text.trim(),
        _selectedUserIds,
        currentUser!.uid,
        _groupImage,
      );
      if(mounted) Navigator.pop(context);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Grupo"), backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createGroup,
        backgroundColor: const Color(0xFF25D366),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    backgroundImage: _groupImage != null ? MemoryImage(_groupImage!) : null,
                    child: _groupImage == null ? const Icon(Icons.camera_alt, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: "Nombre del grupo"),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Seleccionar Participantes", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final uid = user['uid'];
                    if (uid == currentUser?.uid) return const SizedBox.shrink();

                    final isSelected = _selectedUserIds.contains(uid);

                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(user['photoURL'] ?? "https://via.placeholder.com/150")),
                      title: Text(user['displayName'] ?? "Sin nombre"),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF075E54),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedUserIds.add(uid);
                            } else {
                              _selectedUserIds.remove(uid);
                            }
                          });
                        },
                      ),
                      onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(uid);
                            } else {
                              _selectedUserIds.add(uid);
                            }
                          });
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