import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotificationsEnabled = true; // Ejemplo de estado
  bool _activityEmailsEnabled = false; // Ejemplo de estado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Ajustes de Notificaciones', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notificaciones Push', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Recibe alertas en tu dispositivo.', style: TextStyle(color: Colors.white70)),
            value: _pushNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _pushNotificationsEnabled = value;
                // Aquí deberías guardar esta preferencia en Firestore para el usuario.
                // Y si usas Firebase Cloud Messaging, gestionar la suscripción/desuscripción.
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notificaciones Push: ${value ? "Activadas" : "Desactivadas"}')),
              );
            },
            activeColor: Colors.purpleAccent,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[700],
          ),
          SwitchListTile(
            title: const Text('Correos de Actividad', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Recibe resúmenes y alertas por correo electrónico.', style: TextStyle(color: Colors.white70)),
            value: _activityEmailsEnabled,
            onChanged: (bool value) {
              setState(() {
                _activityEmailsEnabled = value;
                // Aquí deberías guardar esta preferencia en Firestore para el usuario.
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Correos de Actividad: ${value ? "Activados" : "Desactivados"}')),
              );
            },
            activeColor: Colors.purpleAccent,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[700],
          ),
          // Puedes añadir más opciones de notificación por categoría aquí si lo deseas.
          // Por ejemplo, usando CheckboxListTile o Navigation para otra pantalla.
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aquí también puedes gestionar notificaciones específicas por categorías de vehículos.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}