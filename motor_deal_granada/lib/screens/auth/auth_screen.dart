import 'package:flutter/material.dart';
import 'package:motor_deal_granada/main.dart'; 
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo de la aplicación
            Image.asset(
              'assets/image/logo.png',
              width: 200,
              height: 150,
            ),
            const SizedBox(height: 20),
            // Botón de Login
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(loginScreenRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6200EA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            // Botón de Sign Up
            ElevatedButton(
              onPressed: () {
                // Navega a la pantalla de registro
                Navigator.of(context).pushNamed(signUpScreenRoute); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
