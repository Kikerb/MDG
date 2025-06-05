import 'package:flutter/material.dart';
import 'package:motor_deal_granada/main.dart'; // Importa main.dart para las rutas

class AuthScreen extends StatelessWidget { // Cambiamos a StatelessWidget si solo son botones
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro

      body: Center( // Centra el contenido en la pantalla
        child: SingleChildScrollView( // Permite el scroll si el contenido es mucho
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente los elementos
            crossAxisAlignment: CrossAxisAlignment.center, // Centra horizontalmente los elementos
            children: <Widget>[
              // Logo de la aplicación
              Image.asset(
                'assets/image/logo.png', // <--- Asegúrate de tener esta imagen (logo del coche)
                width: 250, // Ajusta el tamaño
                height: 150,
              ),
              const Text(
                'MotorDealGranada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'MDG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 80), // Espacio entre el texto y los botones

              // Botón de Login
              SizedBox(
                width: double.infinity, // Ocupa todo el ancho disponible
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(loginScreenRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EA), // Color morado fuerte
                    foregroundColor: Colors.white, // Texto blanco
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Bordes más redondeados
                    ),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16), // Espacio entre botones

              // Botón de Sign Up
              SizedBox(
                width: double.infinity, // Ocupa todo el ancho disponible
                child: ElevatedButton(
                  onPressed: () {
                    // Navega a la pantalla de registro (SignUpScreen)
                    Navigator.of(context).pushNamed(signUpScreenRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Fondo blanco
                    foregroundColor: Colors.black, // Texto negro
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Bordes más redondeados
                    ),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                ),
              ),
              // Aquí podrías añadir los círculos blancos y los íconos si son elementos decorativos fijos
            ],
          ),
        ),
      ),
    );
  }
}

