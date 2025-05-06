import 'package:flutter/material.dart';
import 'package:motor_deal_granada/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulamos una pantalla de carga con un temporizador.
    Future.delayed(const Duration(seconds: 2), () {
      // Después de 2 segundos, navegamos a la pantalla de autenticación.
      Navigator.of(context).pushReplacementNamed(authScreenRoute);
    });

    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro como en tu diseño
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Aquí iría el logo de tu aplicación.  He usado un texto como ejemplo.
            const Text(
              'MotorDeal Granada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Puedes agregar un indicador de carga aquí si lo deseas
            const CircularProgressIndicator(color: Colors.white,),
          ],
        ),
      ),
    );
  }
}