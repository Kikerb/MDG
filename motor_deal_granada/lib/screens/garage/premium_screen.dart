import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _selectedDuration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Obtén Premium',
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
              Icons.workspace_premium,
              color: Colors.amberAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Desbloquea Funciones Exclusivas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildPremiumFeature('Más espacio en el garaje', 'Añade hasta 10 vehículos más para tu colección.'),
            _buildPremiumFeature('Tasador de coches por IA', 'Obtén valoraciones precisas de tus vehículos con nuestra inteligencia artificial.'),
            _buildPremiumFeature('Soporte prioritario', 'Obtén ayuda rápida de nuestro equipo de soporte dedicado.'),
            _buildPremiumFeature('Sin anuncios', 'Disfruta de una experiencia totalmente fluida y sin interrupciones.'),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.purpleAccent, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  hint: const Text(
                    'Selecciona la duración de la suscripción',
                    style: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: Colors.grey[850],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDuration = newValue;
                    });
                  },
                  items: <String>['1 mes', '3 meses', '1 año']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedDuration == null
                  ? null
                  : () async { // Marcar como async para usar await
                      // Simula la compra
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Felicidades! Has simulado la compra de la suscripción Premium por $_selectedDuration. ¡Disfruta de tus nuevas ventajas!',
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.lightGreen,
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      // Lógica para actualizar el estado del usuario en Firestore
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                            {'isPremiumUser': true}, // Establece isPremiumUser a true
                            SetOptions(merge: true), // Usa merge para no sobrescribir otros campos
                          );
                          print('isPremiumUser actualizado a true en Firestore para ${user.uid}');
                        } catch (e) {
                          print('Error al actualizar isPremiumUser en Firestore: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al activar el Premium: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        print('Usuario no autenticado, no se puede actualizar isPremiumUser.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                shadowColor: Colors.amberAccent,
                elevation: 8,
              ),
              child: const Text(
                'Simular Compra Premium',
                style: TextStyle(
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

  Widget _buildPremiumFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.lightGreenAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
