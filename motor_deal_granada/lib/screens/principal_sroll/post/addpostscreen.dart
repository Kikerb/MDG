import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Para el tipo File
import 'package:firebase_storage/firebase_storage.dart'; // Para subir imágenes a Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // Para guardar datos en Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el usuario actual

import '/main.dart'; // Importa main.dart para las rutas nombradas (ej. para volver a la pantalla principal)
import '/models/vehicle_model.dart'; // Importa tu modelo de vehículo
import 'select_vehicle_screen.dart'; // La nueva pantalla para seleccionar un vehículo

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Estado para la imagen seleccionada y la descripción
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false; // Para mostrar un indicador de carga
  VehicleModel? _selectedVehicle; // Para almacenar el vehículo asociado al post

  @override
  void initState() {
    super.initState();
    // Asegurarse de que el usuario esté autenticado antes de intentar cualquier operación de Firebase
    if (_auth.currentUser == null) {
      // Si no hay usuario, redirigir a la pantalla de inicio de sesión o mostrar un mensaje
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(loginScreenRoute);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Método para seleccionar una imagen (desde cámara o galería)
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
      print('Error al seleccionar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // Muestra un BottomSheet para elegir entre cámara o galería
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
                title: const Text('Tomar foto', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Seleccionar de galería', style: TextStyle(color: Colors.white)),
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

  // Método para seleccionar un vehículo existente del usuario
  Future<void> _selectVehicle() async {
    final selectedVehicle = await Navigator.push<VehicleModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectVehicleScreen(),
      ),
    );

    if (selectedVehicle != null) {
      setState(() {
        _selectedVehicle = selectedVehicle;
      });
    }
  }

  // Método para subir el post a Firebase
  Future<void> _uploadPost() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen para tu publicación.')),
      );
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un vehículo para tu publicación.')),
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

      // 1. Subir imagen a Firebase Storage
      String fileName = 'posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. Obtener datos del usuario para el post
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String username = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['name'] ?? user.email : user.email ?? 'Usuario Desconocido';
      String userProfileImageUrl = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png' : 'https://i.imgur.com/BoN9kdC.png';


      // 3. Guardar el post en Firestore
      await _firestore.collection('posts').add({
        'userId': user.uid,
        'username': username,
        'userProfileImageUrl': userProfileImageUrl, // Añadir URL de imagen de perfil del usuario
        'imageUrl': imageUrl,
        'description': _descriptionController.text.trim(),
        'vehicleId': _selectedVehicle!.id, // Enlazar con el ID del vehículo
        'vehicleBrand': _selectedVehicle!.brand, // Opcional: guardar algunos detalles del vehículo para visualización rápida
        'vehicleModel': _selectedVehicle!.model,
        'timestamp': FieldValue.serverTimestamp(), // Marca de tiempo del servidor
        'likes': 0,
        'commentsCount': 0,
        'shares': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada con éxito!')),
        );
        Navigator.of(context).pop(); // Vuelve a la pantalla anterior (Garaje)
      }
    } catch (e) {
      print('Error al subir publicación: $e');
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
        title: const Text('Crear Publicación', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A0033),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A0033),
                Color.fromARGB(255, 60, 0, 100),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Cierra la pantalla de publicación
          },
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadPost,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Publicar',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Área para la imagen seleccionada
                  GestureDetector(
                    onTap: _showImageSourceActionSheet,
                    child: Container(
                      height: MediaQuery.of(context).size.width * 0.8, // Cuadrado o casi cuadrado
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 60, color: Colors.white54),
                                SizedBox(height: 10),
                                Text(
                                  'Toca para añadir imagen',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de descripción
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe una descripción para tu publicación...',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selección de vehículo
                  ElevatedButton.icon(
                    onPressed: _selectVehicle,
                    icon: const Icon(Icons.directions_car, color: Colors.white),
                    label: Text(
                      _selectedVehicle != null
                          ? 'Vehículo: ${_selectedVehicle!.brand} ${_selectedVehicle!.model}'
                          : 'Seleccionar Vehículo',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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

                  // Puedes añadir más campos aquí si es necesario, como etiquetas, ubicación, etc.
                ],
              ),
            ),
    );
  }
}
