import 'package:flutter/material.dart';
import 'package:motor_deal_granada/main.dart'; // Importa main.dart para las rutas
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signUp() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, introduce tu correo y contraseña.')),
        );
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Registro exitoso, redirige a login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Usuario registrado con éxito! Por favor, inicia sesión.')),
      );
      // Redirige a la pantalla de login después de un registro exitoso
      Navigator.of(context).pushReplacementNamed(loginScreenRoute);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al registrar usuario.';
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'El formato del correo electrónico es inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error desconocido al registrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro
      appBar: AppBar(
        backgroundColor: Colors.black, // AppBar con fondo negro
        elevation: 0, // Sin sombra
        title: const Text(
          'Registro', // Título de la AppBar en español
          style: TextStyle(color: Colors.white), // Texto blanco
        ),
      ),
      body: SingleChildScrollView( // Permite el desplazamiento si el contenido es demasiado largo
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0), // Padding horizontal y vertical
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos verticalmente
          crossAxisAlignment: CrossAxisAlignment.center, // Centra los elementos horizontalmente
          children: <Widget>[
            // Logo de la aplicación
            Image.asset(
              'assets/image/logo.png', // Asegúrate de que esta ruta sea correcta
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
            const SizedBox(height: 50), // Espacio entre el logo y los campos de texto

            // Campo de texto para Email
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A0033), // Fondo morado oscuro para la entrada
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade700), // Borde sutil
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white), // Texto blanco
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico', // Texto en español
                  labelStyle: TextStyle(color: Colors.grey), // Color de la etiqueta
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none, // Sin borde por defecto
                ),
              ),
            ),
            const SizedBox(height: 16), // Espacio entre campos

            // Campo de texto para Contraseña
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A0033), // Fondo morado oscuro para la entrada
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade700), // Borde sutil
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white), // Texto blanco
                decoration: const InputDecoration(
                  labelText: 'Contraseña', // Texto en español
                  labelStyle: TextStyle(color: Colors.grey), // Color de la etiqueta
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none, // Sin borde por defecto
                ),
              ),
            ),
            const SizedBox(height: 20), // Espacio antes del botón de registro

            // Botón de Registrarse
            SizedBox(
              width: double.infinity, // Ocupa todo el ancho
              child: ElevatedButton(
                onPressed: _signUp, // Llama a la función de registro
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7), // Fondo morado
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bordes redondeados
                  ),
                ),
                child: const Text(
                  'Registrarse', // Texto en español
                  style: TextStyle(fontSize: 18, color: Colors.white), // Texto blanco
                ),
              ),
            ),

            const SizedBox(height: 30), // Espacio antes del texto de "Ya tienes cuenta?"

            // Texto "¿Ya tienes una cuenta? Inicia sesión"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¿Ya tienes una cuenta? ', // Texto en español
                  style: TextStyle(color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    // Navega a la pantalla de login
                    Navigator.of(context).pushReplacementNamed(loginScreenRoute);
                  },
                  child: const Text(
                    'Inicia sesión', // Texto en español
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón "Registrarse con Google" (si aplica para esta pantalla)
            OutlinedButton(
              onPressed: () {
                // Lógica para el registro con Google
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey), // Borde gris
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/image/google_logo.png', // Asegúrate de tener esta imagen
                    height: 24.0,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Registrarse con Google', // Texto en español
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // Texto "Motor Deal Granada" en la parte inferior
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
    );
  }
}