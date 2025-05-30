import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/models/vehicle_model.dart'; // Importa tu modelo de vehículo

class SelectVehicleScreen extends StatefulWidget {
  const SelectVehicleScreen({super.key});

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Seleccionar Vehículo', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1A0033),
        ),
        body: const Center(
          child: Text(
            'Debes iniciar sesión para seleccionar un vehículo.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Seleccionar Vehículo', style: TextStyle(color: Colors.white)),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('vehicles')
            .where('userId', isEqualTo: _currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar vehículos: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No tienes vehículos en tu garaje. Añade uno primero.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final List<VehicleModel> vehicles = snapshot.data!.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(vehicle.mainImageUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Manejar error de carga de imagen, por ejemplo, mostrar un icono
                      print('Error cargando imagen del vehículo: $exception');
                    },
                  ),
                  title: Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Año: ${vehicle.year}, Estado: ${vehicle.currentStatus}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.pop(context, vehicle); // Devuelve el vehículo seleccionado
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
