import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/part_model.dart';

class CreatePartScreen extends StatefulWidget {
  const CreatePartScreen({super.key});

  @override
  State<CreatePartScreen> createState() => _CreatePartScreenState();
}

class _CreatePartScreenState extends State<CreatePartScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(text: "EUR");
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _compatibilityController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    final fileName = 'parts/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, selecciona una imagen.")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Usuario no autenticado");

      final imageUrl = await _uploadImage(_selectedImage!);

      final newPart = PartModel(
        id: '', // Se autogenerará en Firestore
        userId: userId,
        partName: _partNameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        currency: _currencyController.text.trim(),
        condition: _conditionController.text.trim(),
        imageUrl: imageUrl,
        vehicleCompatibility: _compatibilityController.text.split(',').map((e) => e.trim()).toList(),
        location: null, // Por ahora null
        listedAt: Timestamp.now(),
        isSold: false,
      );

      final docRef = await FirebaseFirestore.instance.collection('parts').add(newPart.toFirestore());

      // Puedes usar docRef.id para actualizar el ID si lo deseas
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pieza publicada correctamente")));
      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _conditionController.dispose();
    _compatibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Pieza"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImage == null
                              ? const Center(child: Text("Toca para seleccionar una imagen"))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _partNameController,
                        decoration: const InputDecoration(labelText: "Nombre de la pieza"),
                        validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: "Descripción"),
                        maxLines: 3,
                        validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: "Precio"),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final number = double.tryParse(value ?? '');
                          if (number == null || number <= 0) return "Ingresa un precio válido";
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(labelText: "Moneda (EUR, USD...)"),
                        validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: _conditionController,
                        decoration: const InputDecoration(labelText: "Condición"),
                        validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                      ),
                      TextFormField(
                        controller: _compatibilityController,
                        decoration: const InputDecoration(
                          labelText: "Compatibilidad (separa con comas)",
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.check),
                        label: const Text("Publicar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
