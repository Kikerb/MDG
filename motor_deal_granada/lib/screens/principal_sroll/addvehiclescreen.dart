import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Para trabajar con archivos File
import 'package:geolocator/geolocator.dart'; // Opcional para GeoPoint
import '../../models/vehicle_model.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario

  // Controladores para los campos de texto
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _vinController = TextEditingController(); // VIN es opcional

  // Variables para Dropdowns
  String? _selectedVehicleType;
  String? _selectedCurrentStatus;
  String? _selectedFuelType;
  String? _selectedCurrency = 'EUR'; // Valor por defecto

  // Lista de opciones para los Dropdowns
  final List<String> _vehicleTypes = ['Coche', 'Moto', 'Furgoneta', 'Camión', 'Otro'];
  final List<String> _currentStatuses = ['En Venta', 'Escucha Ofertas', 'No en Venta'];
  final List<String> _fuelTypes = ['Gasolina', 'Diésel', 'Eléctrico', 'Híbrido', 'Otro'];
  final List<String> _currencies = ['EUR', 'USD', 'GBP']; // Puedes añadir más

  File? _mainImageFile; // Archivo de la imagen seleccionada

  bool _isLoading = false; // Estado para el indicador de carga
  String? _userId; // ID del usuario actual

  GeoPoint? _currentLocation; // Para almacenar la ubicación

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    // _getCurrentLocation(); // Descomenta si quieres obtener la ubicación automáticamente al cargar
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  // --- Métodos de Ayuda ---

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    } else {
      // Manejar el caso de que el usuario no esté logueado (ej. redirigir a login)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para añadir un vehículo.')),
      );
      Navigator.of(context).pop(); // O redirigir a pantalla de login
    }
  }

  // Opcional: Obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permiso de ubicación denegado');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Permiso de ubicación denegado permanentemente');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación obtenida.')),
      );
    } catch (e) {
      print('Error al obtener ubicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _mainImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final String fileName = 'vehicles/${_userId}/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen a Firebase Storage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
      return null;
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      if (_mainImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una imagen principal para el vehículo.')),
        );
        return;
      }
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado. Por favor, reinicia la app.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Subir la imagen a Firebase Storage
        final String? imageUrl = await _uploadImage(_mainImageFile!);
        if (imageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return; // Falló la subida de la imagen
        }

        // 2. Crear el VehicleModel
        final String docId = FirebaseFirestore.instance.collection('vehicles').doc().id; // Genera un ID de documento
        final Timestamp now = Timestamp.now();

        final VehicleModel newVehicle = VehicleModel(
          id: docId,
          userId: _userId!, // Sabemos que no es null aquí
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text.trim()),
          description: _descriptionController.text.trim(),
          mainImageUrl: imageUrl,
          addedAt: now,
          vehicleType: _selectedVehicleType!, // Sabemos que no es null por la validación
          currentStatus: _selectedCurrentStatus!, // Sabemos que no es null
          price: _selectedCurrentStatus == 'En Venta' ? double.tryParse(_priceController.text.trim()) : null,
          currency: _selectedCurrentStatus == 'En Venta' ? _selectedCurrency : null,
          mileage: int.parse(_mileageController.text.trim()),
          fuelType: _selectedFuelType!, // Sabemos que no es null
          location: _currentLocation, // Puede ser null si no se obtuvo
          vin: _vinController.text.trim().isNotEmpty ? _vinController.text.trim() : null,
          lastModified: now,
          isActive: true,
        );

        // 3. Guardar en Firestore
        await FirebaseFirestore.instance.collection('vehicles').doc(docId).set(newVehicle.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo añadido exitosamente!')),
        );
        Navigator.of(context).pop(); // Vuelve a la pantalla anterior
      } catch (e) {
        print('Error al guardar vehículo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar vehículo: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0033),
      appBar: AppBar(
        title: const Text('Añadir Vehículo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A0033),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Selector de Imagen Principal ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent, width: 2),
                        ),
                        child: _mainImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_mainImageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.white70),
                                  SizedBox(height: 10),
                                  Text(
                                    'Toca para añadir imagen principal',
                                    style: TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Campos del Formulario ---

                    _buildTextField(_brandController, 'Marca', 'Ingresa la marca del vehículo', false),
                    _buildTextField(_modelController, 'Modelo', 'Ingresa el modelo del vehículo', false),
                    _buildTextField(_yearController, 'Año', 'Ej: 2020', false, keyboardType: TextInputType.number),
                    _buildTextField(_mileageController, 'Kilometraje (km)', 'Ej: 50000', false, keyboardType: TextInputType.number),
                    _buildTextField(_descriptionController, 'Descripción', 'Describe tu vehículo (estado, características, etc.)', false, maxLines: 3),
                    _buildTextField(_vinController, 'VIN (Opcional)', 'Número de Identificación del Vehículo', true), // Opcional

                    // Dropdowns
                    _buildDropdownField(
                      'Tipo de Vehículo',
                      _selectedVehicleType,
                      _vehicleTypes,
                      (String? newValue) {
                        setState(() {
                          _selectedVehicleType = newValue;
                        });
                      },
                      'Selecciona el tipo de vehículo',
                    ),
                    _buildDropdownField(
                      'Combustible',
                      _selectedFuelType,
                      _fuelTypes,
                      (String? newValue) {
                        setState(() {
                          _selectedFuelType = newValue;
                        });
                      },
                      'Selecciona el tipo de combustible',
                    ),
                    _buildDropdownField(
                      'Estado Actual',
                      _selectedCurrentStatus,
                      _currentStatuses,
                      (String? newValue) {
                        setState(() {
                          _selectedCurrentStatus = newValue;
                        });
                      },
                      'Selecciona el estado del vehículo',
                    ),

                    // Campo de Precio (condicional)
                    if (_selectedCurrentStatus == 'En Venta')
                      Column(
                        children: [
                          _buildTextField(_priceController, 'Precio', 'Ej: 15000.00', false, keyboardType: TextInputType.number),
                          _buildDropdownField(
                            'Moneda',
                            _selectedCurrency,
                            _currencies,
                            (String? newValue) {
                              setState(() {
                                _selectedCurrency = newValue;
                              });
                            },
                            'Selecciona la moneda',
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),

                    // Botón para obtener ubicación (opcional)
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: Text(
                        _currentLocation != null
                            ? 'Ubicación: Lat ${_currentLocation!.latitude.toStringAsFixed(4)}, Lon ${_currentLocation!.longitude.toStringAsFixed(4)}'
                            : 'Obtener Ubicación Actual (Opcional)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón de Guardar
                    ElevatedButton(
                      onPressed: _saveVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent, // Color de botón
                        minimumSize: const Size(double.infinity, 50), // Ancho completo
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Guardar Vehículo',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Widgets de Ayuda para construir el formulario ---

  Widget _buildTextField(TextEditingController controller, String label, String hint, bool isOptional, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.purpleAccent),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio.';
          }
          if (keyboardType == TextInputType.number) {
            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Por favor, ingresa un número válido.';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged, String hintText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(hintText, style: TextStyle(color: Colors.white54)),
        dropdownColor: const Color(0xFF1A0033), // Color de fondo del desplegable
        style: const TextStyle(color: Colors.white), // Color del texto seleccionado
        icon: const Icon(Icons.arrow_drop_down, color: Colors.purpleAccent),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.purpleAccent),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, selecciona una opción.';
          }
          return null;
        },
      ),
    );
  }
}