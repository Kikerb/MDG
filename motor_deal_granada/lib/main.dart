import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/login/login_screen.dart';

// Definimos constantes para las rutas de las pantallas para facilitar la navegación y evitar errores tipográficos.
const String splashScreenRoute = '/splash';
const String authScreenRoute = '/auth';
const String loginScreenRoute = '/login';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotorDeal Granada',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
      ),
      // Definimos las rutas de la aplicación.  Esto nos permite navegar entre pantallas usando nombres.
      initialRoute: splashScreenRoute, // La pantalla de inicio será la de Splash
      routes: {
        splashScreenRoute: (context) => const SplashScreen(),
        authScreenRoute: (context) => const AuthScreen(),
        loginScreenRoute: (context) => const LoginScreen(),
      },
    );
  }
}