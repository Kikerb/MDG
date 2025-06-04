import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces externos

// Importa el bottom sheet para la cuenta
import '../../widgets/account_settings_bottom_sheet.dart';
// Importa las nuevas pantallas para las otras secciones
import '../garage/favorite_vehicles_screen.dart'; // Ejemplo de pantalla de preferencias
import 'blocked_users_screen.dart'; // Ya existe, pero lo reconfirmo
import 'interest_categories_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';

class ConfiguracionUser extends StatelessWidget {
  const ConfiguracionUser({super.key});

  // Función para abrir URLs externas (Términos, Política de Privacidad)
  Future<void> _launchURL(BuildContext context, String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print('No se pudo lanzar la URL: $url');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Cuenta',
            items: [
              _SettingsItem(
                text: 'Gestionar opciones de cuenta',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Permite que el sheet ocupe más espacio
                    builder: (context) {
                      return const AccountSettingsBottomSheet();
                    },
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Preferencias automotrices',
            items: [
              _SettingsItem(
                text: 'Vehículos favoritos',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteVehiclesScreen()));
                },
              ),
              _SettingsItem(
                text: 'Categorías de interés',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InterestCategoriesScreen()));
                },
              ),
              _SettingsItem(
                text: 'Notificaciones por categoría',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                  // Puedes usar la misma pantalla de notificaciones, o una específica para categoría
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Notificaciones',
            items: [
              _SettingsItem(
                text: 'Gestionar notificaciones push', // Texto más descriptivo
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                },
              ),
              _SettingsItem(
                text: 'Gestionar correos de actividad', // Texto más descriptivo
                onTap: () {
                  // Podría ser la misma pantalla de notificaciones o una más específica
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Privacidad',
            items: [
              _SettingsItem(
                text: 'Configurar privacidad de mensajes', // Texto más descriptivo
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
                },
              ),
              _SettingsItem(
                text: 'Configurar privacidad de comentarios', // Texto más descriptivo
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()));
                  // Puedes usar la misma pantalla de privacidad o una específica
                },
              ),
              _SettingsItem(
                text: 'Usuarios bloqueados',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen()));
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'App',
            items: [
              _SettingsItem(
                text: 'Tema (oscuro/claro)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cambiar tema (próximamente)')),
                  );
                },
              ),
              _SettingsItem(
                text: 'Idioma',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cambiar idioma (próximamente)')),
                  );
                },
              ),
              _SettingsItem(
                text: 'Versión de la app',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Mi Garaje App',
                    applicationVersion: '1.0.0', // Puedes obtener esto dinámicamente con package_info_plus
                    applicationLegalese: '© 2024 Mi Garaje App. Todos los derechos reservados.',
                  );
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Legal',
            items: [
              _SettingsItem(
                text: 'Términos y condiciones',
                onTap: () => _launchURL(context, 'https://www.ejemplo.com/terminos'), // Reemplaza con tu URL real
              ),
              _SettingsItem(
                text: 'Política de privacidad',
                onTap: () => _launchURL(context, 'https://www.ejemplo.com/privacidad'), // Reemplaza con tu URL real
              ),
              _SettingsItem(
                text: 'Reportar un problema',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formulario de reporte de problemas (próximamente)')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Estos widgets auxiliares _SettingsItem y _SettingsSection se mantienen igual.
class _SettingsItem extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isDestructive
          ? const Icon(Icons.warning_amber, color: Colors.redAccent, size: 18)
          : const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
      onTap: onTap,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      collapsedIconColor: Colors.white54,
      iconColor: Colors.purpleAccent,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.purpleAccent,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      children: items,
    );
  }
}