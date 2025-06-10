import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createNotification({
  required String receiverUserId,  // Usuario que recibe la notificación
  required String senderName,      // Nombre del usuario que genera la acción
  required String type,            // Tipo: 'message', 'offer', 'like', 'comment', 'share'
  String? vehicleName,             // Nombre del vehículo (para ofertas)
  String? postTitle,               // Título de la publicación (para likes, comentarios, shares)
  String? relatedId,               // ID relacionada (chatId, offerId, postId, etc)
}) async {
  final notificationData = {
    'userId': receiverUserId,
    'senderName': senderName,
    'type': type,
    'vehicleName': vehicleName,
    'postTitle': postTitle,
    'relatedId': relatedId,
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,  // Para controlar si la notificación ya fue vista
  };

  await FirebaseFirestore.instance.collection('Notifications').add(notificationData);
}
