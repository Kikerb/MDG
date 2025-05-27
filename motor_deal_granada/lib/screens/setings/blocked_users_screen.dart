import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Usuarios Bloqueados', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aquí se mostrará la lista de usuarios bloqueados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              // Aquí iría un ListView.builder que muestre los usuarios bloqueados
              // (leídos desde Firestore para el usuario actual) y un botón para desbloquearlos.
            ],
          ),
        ),
      ),
    );
  }
}