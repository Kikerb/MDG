import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MenuOpcionesPerfil extends StatefulWidget {
  const MenuOpcionesPerfil({super.key});

  @override
  State<MenuOpcionesPerfil> createState() => _MenuOpcionesPerfilState();
}

class _MenuOpcionesPerfilState extends State<MenuOpcionesPerfil> {
  Future<void> _mostrarSeleccionImagen(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Usar Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final file = File(picked.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();

        // Actualiza la URL en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
        });
        // No necesitas llamar a setState aquí porque el StreamBuilder escuchará el cambio
      }
    }
  }

  void _mostrarMenu(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _opcionMenu(Icons.camera_alt, 'Cambiar Foto de Perfil', () {
                Navigator.pop(context);
                _mostrarSeleccionImagen(context);
              }),
              _opcionMenu(Icons.person, 'Configuración de la cuenta', () {
                Navigator.pop(context);
                // Aquí puedes agregar navegación o lógica para configuración
              }),
              _opcionMenu(Icons.logout, 'Cerrar Sesión', () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionMenu(IconData icono, String texto, VoidCallback accion) {
    return ListTile(
      leading: Icon(icono, color: Colors.purpleAccent),
      title: Text(texto, style: const TextStyle(color: Colors.white)),
      onTap: accion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Icon(Icons.account_circle, color: Colors.white);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['profileImageUrl'];
        }

        return IconButton(
          icon: CircleAvatar(
            radius: 18,
            backgroundImage: photoUrl != null
                ? NetworkImage(photoUrl)
                : const AssetImage('assets/default_profile.png') as ImageProvider,
            backgroundColor: Colors.grey,
          ),
          onPressed: () => _mostrarMenu(context),
        );
      },
    );
  }
}
