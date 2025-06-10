import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/main.dart'; 
import '/models/vehicle_model.dart';
import '/models/post_model.dart';
import 'select_vehicle_screen.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  VehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Seleccionar de galería',
                  style: TextStyle(color: Colors.white),
                ),
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

  Future<void> _selectVehicle() async {
    final selectedVehicle = await Navigator.push<VehicleModel>(
      context,
      MaterialPageRoute(builder: (context) => const SelectVehicleScreen()),
    );

    if (selectedVehicle != null) {
      setState(() {
        _selectedVehicle = selectedVehicle;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona una imagen para tu publicación.',
          ),
        ),
      );
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona un vehículo para tu publicación.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      String fileName =
          'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage
          .ref()
          .child(fileName)
          .putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      String username =
          userDoc.exists
              ? (userDoc.data() as Map<String, dynamic>)['username'] ?? user.email // Changed 'name' to 'username' based on common practice
              : user.email ?? 'Usuario Desconocido';
      String? userProfileImageUrl =
          userDoc.exists
              ? (userDoc.data() as Map<String, dynamic>)['profileImageUrl']
              : null;

      final newPost = PostModel(
        id: '',
        userId: user.uid,
        username: username,
        profileImageUrl: userProfileImageUrl,
        vehicleId: _selectedVehicle!.id,
        postType: "General",
        imageUrl: imageUrl,
        description: _descriptionController.text.trim(),
        timestamp: Timestamp.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        likedUserIds: [],
        tags: [],
      );

      await _firestore.collection('posts').add(newPost.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada con éxito!')),
        );
        // Redirige a scrollScreenRoute después de publicar
        Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear publicación: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Crear Publicación',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A0033),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0033), Color.fromARGB(255, 60, 0, 100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Redirige a scrollScreenRoute al presionar el botón de cerrar
            Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
          },
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadPost,
            child:
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Publicar',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceActionSheet,
                        child: Container(
                          height: MediaQuery.of(context).size.width * 0.8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child:
                              _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 60,
                                          color: Colors.white54,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Toca para añadir imagen',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Escribe una descripción para tu publicación...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: Colors.purpleAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _selectVehicle,
                        icon: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                        label: Text(
                          _selectedVehicle != null
                              ? 'Vehículo: ${_selectedVehicle!.brand} ${_selectedVehicle!.model}'
                              : 'Seleccionar Vehículo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}