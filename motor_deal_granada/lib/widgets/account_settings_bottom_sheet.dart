import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir URLs, útil si pones enlaces de ayuda

import '../screens/principal_sroll/EditProfileScreen.dart';
import '../screens/principal_sroll/change_email_screen.dart';
import '../screens/principal_sroll/change_password_screen.dart';


class AccountSettingsBottomSheet extends StatelessWidget {
  const AccountSettingsBottomSheet({super.key});

  // Función para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Redirige a la pantalla de login y elimina todas las rutas anteriores
      if (context.mounted) { // Verifica si el widget sigue montado antes de navegar
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Asegúrate de que esta sea la ruta nombrada de tu login
            (Route<dynamic> route) => false
        );
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
        );
      }
    }
  }

  // Función para eliminar cuenta (con confirmación)
  Future<void> _deleteAccount(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible y se perderán todos tus datos.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.purpleAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // --- ADVERTENCIA: LIMPIEZA DE DATOS ---
          // Eliminar el usuario de Firebase Auth NO elimina automáticamente sus datos de Firestore o Storage.
          // Para una aplicación real, deberías implementar Cloud Functions para limpiar todos los datos del usuario (vehículos, fotos, etc.)
          // cuando se elimina su cuenta para evitar datos huérfanos.
          // Por ejemplo:
          // await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
          // etc.
          // --- FIN ADVERTENCIA ---

          await user.delete();
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', // Vuelve al login
                (Route<dynamic> route) => false
            );
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta eliminada correctamente.')),
            );
          }
        }
      } catch (e) {
        print('Error al eliminar cuenta: $e');
        String errorMessage = 'Error al eliminar cuenta.';
        if (e is FirebaseAuthException) {
          if (e.code == 'requires-recent-login') {
            errorMessage = 'Por favor, vuelve a iniciar sesión para eliminar tu cuenta (por seguridad).';
            // Opcional: Aquí podrías pedir al usuario que reautentique
          } else {
            errorMessage = 'Error: ${e.message}';
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Fondo oscuro para el bottom sheet
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Hace que el column ocupe el espacio mínimo necesario
        children: [
          // Barra de arrastre (opcional, pero mejora la usabilidad)
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 16.0),
          ),
          const Text(
            'Ajustes de Cuenta',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            Icons.person,
            'Editar perfil',
            () {
              Navigator.pop(context); // Cierra el bottom sheet
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          _buildOption(
            context,
            Icons.email,
            'Cambiar correo electrónico',
            () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeEmailScreen()));
            },
          ),
          _buildOption(
            context,
            Icons.lock,
            'Cambiar contraseña',
            () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
          _buildOption(
            context,
            Icons.delete_forever,
            'Eliminar cuenta',
            () => _deleteAccount(context), // Llama a la función de eliminación
            isDestructive: true,
          ),
          _buildOption(
            context,
            Icons.logout,
            'Cerrar sesión',
            () => _logout(context), // Llama a la función de cerrar sesión
            isDestructive: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget auxiliar para construir cada opción
  Widget _buildOption(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isDestructive
          ? const Icon(Icons.warning_amber, color: Colors.redAccent, size: 18)
          : const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: () {
        // Ejecuta la función onTap proporcionada
        onTap();
        // Nota: Si la acción no navega a una nueva pantalla, quizás quieras
        // mantener el bottom sheet abierto o cerrarlo explícitamente con Navigator.pop(context);
      },
    );
  }
}