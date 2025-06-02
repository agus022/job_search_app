import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_search_oficial/cubit/user_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<UserCubit>().state.user!;

    nameController = TextEditingController(text: user.name);
    lastNameController = TextEditingController(text: user.lastName);
    phoneController = TextEditingController(text: user.phone);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserCubit>().state.user!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon:
                Icon(isEditing ? Icons.close : Icons.edit, color: Colors.black),
            onPressed: () {
              setState(() => isEditing = !isEditing);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: isEditing
                  ? () => _pickAndUploadImage(user.profilePicture)
                  : null,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: user.profilePicture.isNotEmpty
                    ? NetworkImage(user.profilePicture)
                    : const AssetImage('assets/img/user.webp') as ImageProvider,
                child: isEditing
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            isEditing
                ? _buildEditableField(nameController, 'Nombre')
                : Text('${user.name} ${user.lastName}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user.email,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            isEditing
                ? _buildEditableField(lastNameController, 'Apellido')
                : _buildProfileItem(Icons.person, 'Apellido', user.lastName),
            const SizedBox(height: 16),
            isEditing
                ? _buildEditableField(phoneController, 'Teléfono')
                : _buildProfileItem(Icons.phone, 'Teléfono', user.phone),
            const SizedBox(height: 16),
            _buildProfileItem(
              Icons.work_outline,
              'Rol',
              user.type.name == 'official' ? 'Oficial' : 'Cliente',
            ),
            const SizedBox(height: 24),
            if (isEditing)
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .update({
                    'name': nameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado')),
                  );

                  await context.read<UserCubit>().refreshUser();

                  setState(() {
                    isEditing = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 0, 36),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Guardar cambios'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Future<void> _pickAndUploadImage(String userId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$userId.jpg');

    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Actualiza en Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'profilePicture': downloadUrl});

    // Refresca el UserCubit
    await context.read<UserCubit>().refreshUser();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto de perfil actualizada')),
    );
  }
}
