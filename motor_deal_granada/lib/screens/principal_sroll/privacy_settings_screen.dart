import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // Ejemplo de estado para las preferencias de privacidad
  String _whoCanMessage = 'Todos'; // Opciones: 'Todos', 'Solo mis seguidos', 'Nadie'
  String _whoCanComment = 'Todos'; // Opciones: 'Todos', 'Solo mis seguidos', 'Nadie'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ajustes de Privacidad', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Quién puede enviarme mensajes', style: TextStyle(color: Colors.white)),
            subtitle: Text(_whoCanMessage, style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () async {
              final String? selected = await showModalBottomSheet<String>(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildPrivacyOption('Todos', 'Todos pueden enviarte mensajes.'),
                        _buildPrivacyOption('Solo mis seguidos', 'Solo las personas que sigues pueden enviarte mensajes.'),
                        _buildPrivacyOption('Nadie', 'Nadie puede enviarte mensajes.'),
                      ],
                    ),
                  );
                },
              );
              if (selected != null && selected != _whoCanMessage) {
                setState(() {
                  _whoCanMessage = selected;
                  // Aquí deberías guardar esta preferencia en Firestore para el usuario.
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Configuración de mensajes: $_whoCanMessage')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Quién puede comentar en mis publicaciones', style: TextStyle(color: Colors.white)),
            subtitle: Text(_whoCanComment, style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () async {
              final String? selected = await showModalBottomSheet<String>(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildPrivacyOption('Todos', 'Todos pueden comentar tus publicaciones.'),
                        _buildPrivacyOption('Solo mis seguidos', 'Solo las personas que sigues pueden comentar.'),
                        _buildPrivacyOption('Nadie', 'Nadie puede comentar tus publicaciones.'),
                      ],
                    ),
                  );
                },
              );
              if (selected != null && selected != _whoCanComment) {
                setState(() {
                  _whoCanComment = selected;
                  // Aquí deberías guardar esta preferencia en Firestore para el usuario.
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Configuración de comentarios: $_whoCanComment')),
                );
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Para gestionar usuarios bloqueados, regresa a la pantalla anterior.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(String option, String description) {
    return ListTile(
      title: Text(option, style: const TextStyle(color: Colors.white)),
      subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
      onTap: () => Navigator.pop(context, option),
    );
  }
}