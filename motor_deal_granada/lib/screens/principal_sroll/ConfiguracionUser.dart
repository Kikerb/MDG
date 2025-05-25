import 'package:flutter/material.dart';

class ConfiguracionUser extends StatelessWidget {
  const ConfiguracionUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Configuración',
            style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: const [
          _SettingsSection(title: 'Cuenta', items: [
            'Editar perfil',
            'Cambiar correo electrónico',
            'Cambiar contraseña',
            'Eliminar cuenta',
          ]),
          _SettingsSection(title: 'Preferencias automotrices', items: [
            'Vehículos favoritos',
            'Categorías de interés',
            'Notificaciones por categoría',
          ]),
          _SettingsSection(title: 'Notificaciones', items: [
            'Notificaciones push',
            'Correos de actividad',
          ]),
          _SettingsSection(title: 'Privacidad', items: [
            'Quién puede enviarme mensajes',
            'Quién puede comentar',
            'Usuarios bloqueados',
          ]),
          _SettingsSection(title: 'App', items: [
            'Tema (oscuro/claro)',
            'Idioma',
            'Versión de la app',
          ]),
          _SettingsSection(title: 'Legal', items: [
            'Términos y condiciones',
            'Política de privacidad',
            'Reportar un problema',
          ]),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedIconColor: Colors.white54,
      iconColor: Colors.purpleAccent,
      title: Text(title,
          style: const TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      children: items
          .map((e) => ListTile(
                title: Text(e, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$e" aún no está disponible')),
                  );
                },
              ))
          .toList(),
    );
  }
}
