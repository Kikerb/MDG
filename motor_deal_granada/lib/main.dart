import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:motor_deal_granada/screens/principal_sroll/noticias/Noticias_screen.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/principal_sroll/Scroll.dart';
import 'screens/search/buscar.dart';
import 'screens/principal_sroll/chat/chat_edit.dart' as chat_edit;
import 'screens/garage/garage.dart';
import 'screens/signUp/signUp_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/market/marketscreen.dart';
import 'screens/principal_sroll/post/addpostscreen.dart';
import 'screens/principal_sroll/chat/chat_screen.dart' as chat_screen;

// rutas constantes
const String splashScreenRoute = '/splash';
const String authScreenRoute = '/auth';
const String loginScreenRoute = '/login';
const String signUpScreenRoute = '/signUp';
const String scrollScreenRoute = '/scroll';
const String garageScreenRoute = '/garage';
const String buscarScreenRoute = '/buscar';
const String noticiasScreenRoute = '/noticias';
const String chatScreenRoute = '/chat';
const String cartScreenRoute = '/market';
const String addPostScreenRoute = '/addpost';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => chat_screen.ChatThemeProvider(),
      child: const MyApp(),
    ),
  );
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
      initialRoute: splashScreenRoute,
      routes: {
        splashScreenRoute: (context) => const SplashScreen(),
        authScreenRoute: (context) => const AuthScreen(),
        loginScreenRoute: (context) => const LoginScreen(),
        signUpScreenRoute: (context) => const SignUpScreen(),
        scrollScreenRoute: (context) => const ScrollScreen(),
        garageScreenRoute: (context) => const GarageScreen(),
        buscarScreenRoute: (context) => const BuscarScreen(),
        noticiasScreenRoute: (context) => const NoticiasScreen(),
        cartScreenRoute: (context) => const MarketScreen(),
        addPostScreenRoute: (context) => const AddPostScreen(),
        // Quitamos chatScreenRoute de aquí porque la manejamos en onGenerateRoute
      },
      onGenerateRoute: (settings) {
        if (settings.name == chatScreenRoute) {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null || !args.containsKey('chatId')) {
            // Aquí podrías manejar el error o devolver una pantalla por defecto
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('No se proporcionaron los argumentos necesarios para ChatScreen')),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (context) => chat_screen.ChatScreen(
              chatId: args['chatId'],
              otherUserId: args['otherUserId'],
              otherUserName: args['otherUserName'],
              otherUserEmail: args['otherUserEmail'],
              otherUserProfileImageUrl: args['otherUserProfileImageUrl'],
            ),
          );
        }
        return null; // Deja que flutter maneje otras rutas no definidas
      },
    );
  }
}
