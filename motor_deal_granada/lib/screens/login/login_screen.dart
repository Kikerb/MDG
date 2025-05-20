import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
const String scrollScreenRoute = '/scroll'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Inicio de sesión exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
        );
        // Redirigir a la pantalla Scroll.dart usando la ruta con nombre
        Navigator.pushReplacementNamed(context, scrollScreenRoute); // <--- Cambio aquí
      } on FirebaseAuthException catch (e) {
        // Manejar errores de Firebase Authentication
        String errorMessage = 'Ocurrió un error.';
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Correo electrónico o contraseña incorrectos.';
        } else {
          errorMessage = e.message ?? 'Error desconocido.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Logo de la aplicación
              Image.asset(
                'assets/image/logo.png',
                width: 200,
                height: 150,
              ),
              const Text(
                'MDG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              // Entrada de Email
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0033),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade700),
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo electrónico';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Entrada de Contraseña
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0033),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade700),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              // ¿Olvidaste la contraseña?
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Lógica para manejar la contraseña olvidada
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.purpleAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Botón de Iniciar Sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // ¿No tienes una cuenta? Regístrate
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Lógica para navegar a la pantalla de registro
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Botón de Registrarse con Google
              OutlinedButton(
                onPressed: () {
                  // Lógica para el inicio de sesión con Google
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/image/google_logo.png',
                      height: 24.0,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Registrarse con Google',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              // "Motor Deal Granada" en la parte inferior
              const Text(
                'Motor Deal Granada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}