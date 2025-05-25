import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motor_deal_granada/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  

  // Colores basados en la imagen proporcionada
  final Color _backgroundColor = Colors.black;
  final Color _inputFieldColor = const Color(0xFF4a148c).withOpacity(0.3);
  final Color _inputBorderColor = const Color(0xFF4a148c);
  final Color _primaryColor = const Color(0xFF6200EA);
  final Color _errorColor = Colors.red;
  final Color _textColor = Colors.white;
  final Color _linkTextColor = Colors.blue;

  // Instancia de FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Función para registrar al usuario
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrando usuario...')),
        );

        // *** CAMBIO CLAVE AQUÍ: Convertir el email a minúsculas ANTES de usarlo ***
        final String emailToLower = _emailController.text.trim().toLowerCase();
        final String password = _passwordController.text; // La contraseña no se modifica a minúsculas

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailToLower, // Usa el email en minúsculas para Firebase Authentication
          password: password,
        );

        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
          // Aunque el email de Firebase Auth se guarda en minúsculas,
          // la verificación de email se envía al email original si no se especifica lo contrario.
          // Si necesitas que el email de verificación también sea en minúsculas, tendrías que manejarlo a otro nivel,
          // pero para la búsqueda en Firestore, lo importante es cómo se guarda el campo 'email'.
          await userCredential.user!.sendEmailVerification();

          // Guardar datos adicionales en Firestore
          final userId = userCredential.user!.uid;
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'name': _nameController.text.trim(),
            'email': emailToLower, // <-- ¡GUARDAMOS EL EMAIL EN MINÚSCULAS EN FIRESTORE!
            'phone': _phoneController.text.trim(),
            'followers': [],
            'following': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado con éxito. Por favor, verifica tu correo electrónico.')),
          );

          _showConfirmationDialog();
        }
      } catch (e) {
        String errorMessage = 'Ocurrió un error: ${e.toString()}';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              errorMessage = 'La contraseña es demasiado débil.';
              break;
            case 'email-already-in-use':
              errorMessage = 'Ya existe una cuenta con este correo electrónico.';
              break;
            case 'invalid-email':
              errorMessage = 'El correo electrónico no es válido.';
              break;
            default:
              errorMessage = 'Error al registrar usuario: ${e.message}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  // Función para mostrar el diálogo de confirmación
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registro Exitoso'),
          content: const Text('Usuario registrado con éxito. Por favor, verifica tu correo electrónico.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                Navigator.of(context).pushReplacementNamed(
                    loginScreenRoute); // Navega a la pantalla de inicio de sesión
              },
              child: const Text('Volver a Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo de la aplicación
                  Image.asset(
                    'assets/image/logo.png',
                    width: 200,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  // Campo de Nombre
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: _textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: _inputFieldColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Campo de Correo Electrónico
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: _textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: _inputFieldColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: _textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: _inputFieldColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Campo de Número de Teléfono
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: _textColor),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: _textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _inputBorderColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _errorColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: _inputFieldColor,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 9) {
                        return 'Invalid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Botón de Sign Up
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  // Texto para "Ya tienes una cuenta?"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Do you already have an account? ',
                        style: TextStyle(color: _textColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                              loginScreenRoute); // Navega a la ruta de inicio de sesión
                        },
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            color: _linkTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}