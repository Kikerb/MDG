import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String content;
  final Timestamp timestamp;
  final String type; // Ej: 'text', 'image', 'vehicle_offer', 'part_offer', 'post_shared'
  final String? relatedItemId; // ID del artículo si aplica
  final bool isRead;
  
  // Nuevos campos para post compartido
  final String? postImageUrl;     // URL de la imagen del post compartido
  final String? postDescription;  // Descripción del post compartido
  final String? postUserName;     // Usuario que compartió el post

  MessageModel({
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.relatedItemId,
    this.isRead = false,
    this.postImageUrl,
    this.postDescription,
    this.postUserName,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      type: data['type'] ?? 'text',
      relatedItemId: data['relatedItemId'],
      isRead: data['isRead'] ?? false,
      postImageUrl: data['postImageUrl'],
      postDescription: data['postDescription'],
      postUserName: data['postUserName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'type': type,
      'relatedItemId': relatedItemId,
      'isRead': isRead,
      'postImageUrl': postImageUrl,
      'postDescription': postDescription,
      'postUserName': postUserName,
    };
  }
}
