import 'package:flutter/material.dart';

class InterestCategoriesScreen extends StatelessWidget {
  const InterestCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Categorías de Interés', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aquí podrás seleccionar las categorías de vehículos que más te interesan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              // Aquí iría una lista de CheckboxListTile para que el usuario elija sus categorías preferidas.
              // Las preferencias se guardarían en Firestore.
            ],
          ),
        ),
      ),
    );
  }
}