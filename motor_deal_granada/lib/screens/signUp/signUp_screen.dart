import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  bool isPremiumUser = false;
  int selectedGarageSlots = 3;
  List<String> selectedInterests = [];

  XFile? profileImage;
  String? uploadedImageUrl;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        profileImage = image;
      });
      await uploadProfileImage(File(image.path));
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      final ref = storage.ref().child(
        'profile_images/${auth.currentUser?.uid}.jpg',
      );
      await ref.putFile(imageFile);
      uploadedImageUrl = await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: ${e.toString()}')),
      );
    }
  }

  Future<void> signUp() async {
    if (formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registrando usuario...')));

        final String emailToLower = emailController.text.trim().toLowerCase();
        final String username = usernameController.text.trim();
        final String? bio =
            bioController.text.trim().isEmpty
                ? null
                : bioController.text.trim();
        final String phone = phoneController.text.trim();
        final String password = passwordController.text.trim();

        UserCredential userCredential = await auth
            .createUserWithEmailAndPassword(
              email: emailToLower,
              password: password,
            );

        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(username);
          await userCredential.user!.sendEmailVerification();

          final userId = userCredential.user!.uid;
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'uid': userId,
            'email': emailToLower,
            'username': username,
            'profileImageUrl': uploadedImageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'followersCount': 0,
            'followingCount': 0,
            'garageSlots': selectedGarageSlots,
            'garageSlotsUsed': 0,
            'isPremiumUser': isPremiumUser,
            'lastActive': FieldValue.serverTimestamp(),
            'interests': selectedInterests,
            'bio': bio,
            'phone': phone,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Usuario registrado con éxito. ¡Verifica tu correo electrónico!',
              ),
            ),
          );
          showConfirmationDialog();
        }
      } catch (e) {
        String errorMessage = 'Ocurrió un error: ${e.toString()}';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              errorMessage = 'La contraseña es demasiado débil.';
              break;
            case 'email-already-in-use':
              errorMessage =
                  'Ya existe una cuenta con este correo electrónico.';
              break;
            case 'invalid-email':
              errorMessage = 'El correo electrónico no es válido.';
              break;
            default:
              errorMessage = 'Error al registrar usuario: ${e.message}';
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registro Exitoso'),
          content: const Text(
            'Usuario registrado con éxito. Por favor, verifica tu correo electrónico.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed(loginScreenRoute);
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  backgroundImage:
                      profileImage != null
                          ? FileImage(File(profileImage!.path))
                          : null,
                  child:
                      profileImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.white)
                          : null,
                ),
              ),
              const SizedBox(height: 24),

              buildStyledField(
                usernameController,
                'Nombre de usuario',
                Icons.person,
              ),
              buildStyledField(
                emailController,
                'Correo electrónico',
                Icons.email,
              ),
              buildStyledField(
                passwordController,
                'Contraseña',
                Icons.lock,
                obscure: true,
              ),
              buildStyledField(phoneController, 'Teléfono', Icons.phone),
              buildStyledField(bioController, 'Biografía', Icons.info_outline),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Motor Deal Granada',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStyledField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0033),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade700),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
