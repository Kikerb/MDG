import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TasacionScreen extends StatefulWidget {
  const TasacionScreen({Key? key}) : super(key: key);

  @override
  State<TasacionScreen> createState() => _TasacionScreenState();
}

class _TasacionScreenState extends State<TasacionScreen> {
  final _formKey = GlobalKey<FormState>(); // Key para el formulario
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  // Mapa para almacenar las imágenes seleccionadas por posición
  final Map<String, File?> _carImages = {
    'Frente': null,
    'Atrás': null,
    'Lado Izquierdo': null,
    'Lado Derecho': null,
  };

  bool _isAppraising = false; // Estado para el indicador de carga
  String? _appraisalResult; // Resultado de la tasación

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String position) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _carImages[position] = File(pickedFile.path);
      });
    }
  }

  void _simulateAppraisal() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos del vehículo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_carImages.values.any((image) => image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, sube las 4 fotos del vehículo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isAppraising = true;
      _appraisalResult = null;
    });

    // Simular el proceso de IA con un retardo
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isAppraising = false;
      // Precio simulado por la IA
      _appraisalResult = 'El valor estimado por nuestra IA es: 25.500 €';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Tasación de Vehículos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0033), Color.fromARGB(255, 60, 0, 100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.directions_car,
              color: Colors.lightBlueAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Tasación por Inteligencia Artificial!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ingresa los detalles de tu vehículo y sube las fotos para obtener una valoración estimada por nuestra IA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            // Formulario de Detalles del Vehículo
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_brandController, 'Marca del vehículo'),
                  const SizedBox(height: 15),
                  _buildTextField(_modelController, 'Modelo del vehículo'),
                  const SizedBox(height: 15),
                  _buildTextField(_yearController, 'Año de fabricación',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  _buildTextField(_mileageController, 'Kilometraje (km)',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  // Puedes añadir un Dropdown para el estado del vehículo aquí
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.purpleAccent, width: 1.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[850],
                      decoration: const InputDecoration(
                        labelText: 'Estado del vehículo',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none, // Elimina el borde del TextField
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: <String>[
                        'Excelente',
                        'Bueno',
                        'Normal',
                        'Deteriorado',
                        'Para piezas'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        // Aquí puedes guardar el valor seleccionado si es necesario
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el estado del vehículo';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Sube 4 fotos de tu coche:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            // Sección de subida de fotos
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: _carImages.length,
              itemBuilder: (context, index) {
                String position = _carImages.keys.elementAt(index);
                File? imageFile = _carImages[position];
                return _buildImagePickerCard(position, imageFile);
              },
            ),
            const SizedBox(height: 30),

            // Botón de Tasación
            ElevatedButton(
              onPressed: _isAppraising ? null : _simulateAppraisal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                shadowColor: Colors.blueAccent,
                elevation: 8,
              ),
              child: _isAppraising
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      'Tasar Vehículo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Resultado de la tasación
            if (_appraisalResult != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  _appraisalResult!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para campos de texto
  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo no puede estar vacío';
        }
        return null;
      },
    );
  }

  // Widget auxiliar para la tarjeta de selección de imagen
  Widget _buildImagePickerCard(String position, File? imageFile) {
    return GestureDetector(
      onTap: () => _pickImage(position),
      child: Card(
        color: Colors.grey[900],
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageFile == null)
              Column(
                children: [
                  const Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    position,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              )
            else
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
