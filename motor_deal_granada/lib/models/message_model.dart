import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String content;
  final Timestamp timestamp;
  final String type; // Ej: 'text', 'image', 'vehicle_offer', 'part_offer' [cite: 47]
  final String? relatedItemId; // ID del artículo si el tipo es una oferta (ej., vehículo, pieza) [cite: 47]
  final bool isRead; // Indica si el mensaje ha sido leído por el receptor

  MessageModel({
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text', // Valor por defecto
    this.relatedItemId,
    this.isRead = false, // Valor por defecto
  });

  // Factory constructor para crear un MessageModel desde un DocumentSnapshot de Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      type: data['type'] ?? 'text',
      relatedItemId: data['relatedItemId'],
      isRead: data['isRead'] ?? false,
    );
  }

  // Método para convertir un MessageModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'type': type,
      'relatedItemId': relatedItemId,
      'isRead': isRead,
    };
  }
}