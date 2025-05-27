import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SubirCocheScreen extends StatefulWidget {
  const SubirCocheScreen({Key? key}) : super(key: key);

  @override
  _SubirCocheScreenState createState() => _SubirCocheScreenState();
}

class _SubirCocheScreenState extends State<SubirCocheScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  bool _vendido = false;
  File? _imagenFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (picked != null) {
      setState(() {
        _imagenFile = File(picked.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _imagenFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos y selecciona una imagen')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Referencia para el archivo en Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Subir la imagen y esperar que termine correctamente
      final uploadTask = ref.putFile(_imagenFile!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Crear el post en Firestore
      await FirebaseFirestore.instance.collection('Posts').add({
        'uid': user.uid,
        'username': user.email ?? 'Usuario',
        'imageUrl': imageUrl,
        'description': _descripcionController.text.trim(),
        'vendido': _vendido,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post subido con éxito')),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Coche'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imagenFile == null
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[800],
                        child: const Icon(Icons.add_a_photo, color: Colors.white, size: 50),
                      )
                    : Image.file(_imagenFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: const TextStyle(color: Colors.purpleAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                validator: (value) => value == null || value.isEmpty ? 'Escribe una descripción' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Vendido', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _vendido,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) {
                      setState(() {
                        _vendido = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.purpleAccent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _submitPost,
                      child: const Text('Subir Post'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
