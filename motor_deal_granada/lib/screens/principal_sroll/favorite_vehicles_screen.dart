import 'package:flutter/material.dart';

class FavoriteVehiclesScreen extends StatelessWidget {
  const FavoriteVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Vehículos Favoritos', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aquí se listarán los vehículos que has marcado como favoritos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              // Aquí iría un ListView.builder mostrando los vehículos favoritos del usuario.
              // Los datos se leerían desde Firestore.
            ],
          ),
        ),
      ),
    );
  }
}