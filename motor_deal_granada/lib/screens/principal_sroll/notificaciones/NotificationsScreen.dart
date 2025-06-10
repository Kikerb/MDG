import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _buildNotificationText(Map<String, dynamic> data) {
    final type = data['type'] ?? 'unknown';
    final senderName = data['senderName'] ?? 'Alguien';
    final vehicleName = data['vehicleName'] ?? '';
    final postTitle = data['postTitle'] ?? '';

    switch (type) {
      case 'message':
        return '$senderName te ha enviado un mensaje.';
      case 'offer':
        return '$senderName ha hecho una oferta por tu vehículo "$vehicleName".';
      case 'like':
        return '$senderName ha dado like a tu publicación "$postTitle".';
      case 'comment':
        return '$senderName ha comentado en tu publicación "$postTitle".';
      case 'share':
        return '$senderName ha compartido tu publicación "$postTitle".';
      default:
        return 'Tienes una nueva notificación de $senderName.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes estar autenticado para ver las notificaciones.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('userId', isEqualTo: currentUser.uid) // FILTRAR solo tuyas
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No hay notificaciones.', style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data()! as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final formattedTime = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                  : 'Fecha desconocida';

              final notificationText = _buildNotificationText(data);

              return ListTile(
                leading: Icon(_iconForType(data['type']), color: Colors.purpleAccent),
                title: Text(notificationText, style: const TextStyle(color: Colors.white)),
                subtitle: Text(formattedTime, style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  // Aquí puedes navegar o mostrar detalle según el tipo y relatedId
                  // Ejemplo: Navigator.push(...) para abrir el chat, oferta, publicación, etc.
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'offer':
        return Icons.local_offer;
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      default:
        return Icons.notifications;
    }
  }
}
