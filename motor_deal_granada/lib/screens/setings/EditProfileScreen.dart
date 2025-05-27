import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aquí se editará la información del perfil del usuario.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 20),
              // Aquí irían tus TextFields para nombre, biografía, etc., y el botón de guardar.
              // Puedes usar FirebaseAuth.instance.currentUser para obtener el usuario y Firestore para su información adicional.
            ],
          ),
        ),
      ),
    );
  }
}