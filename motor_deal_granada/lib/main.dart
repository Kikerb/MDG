import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motor_deal_granada/screens/principal_sroll/Noticias_screen.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/signUp/signUp_screen.dart'; 
import 'screens/principal_sroll/Scroll.dart'; 
import 'screens/splash/splash_screen.dart';
import 'screens/principal_sroll/garage.dart'; 

import 'screens/principal_sroll/buscar.dart'; 

// Definimos constantes para las rutas de las pantallas para facilitar la navegación y evitar errores tipográficos.
const String splashScreenRoute = '/splash';
const String authScreenRoute = '/auth';
const String loginScreenRoute = '/login';
const String signUpScreenRoute = '/signUp'; 
const String scrollScreenRoute = '/scroll'; 
const String garageScreenRoute = '/garage';
const String buscarScreenRoute = '/buscar';
const String noticiasScreenRoute = '/noticias';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Usar configuración generada
  );
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
      // Definimos las rutas de la aplicación. Esto nos permite navegar entre pantallas usando nombres.
      initialRoute: splashScreenRoute, // La pantalla de inicio será la de Splash
      routes: {
        splashScreenRoute: (context) => const SplashScreen(),
        authScreenRoute: (context) => const AuthScreen(),
        loginScreenRoute: (context) => const LoginScreen(),
        signUpScreenRoute: (context) => const SignUpScreen(), 
        scrollScreenRoute: (context) => const ScrollScreen(), 
        garageScreenRoute: (context) => const GarageScreen(),
        buscarScreenRoute: (context) => const BuscarScreen(),
        noticiasScreenRoute: (context) => const NoticiasScreen(),
      },
    );
  }
}