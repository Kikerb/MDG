import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id; // ID del documento de la conversación (ej., "chat_uid1_uid2")
  final List<String> participants; // UIDs de los dos participantes
  final String lastMessageContent; // Contenido del último mensaje enviado
  final Timestamp lastMessageTimestamp; // Marca de tiempo del último mensaje
  final String lastMessageSenderId; // UID del remitente del último mensaje
  final Map<String, int> unreadCounts; // {UID1: count1, UID2: count2}
  final bool isGroupChat;
  final String? groupName;
  final String? groupImageUrl;
  

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessageContent,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.unreadCounts,
    this.isGroupChat = false, // Por defecto es false si no se especifica
    this.groupName,
    this.groupImageUrl,
  });

  // Factory constructor para crear un ChatModel desde un DocumentSnapshot de Firestore
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessageContent: data['lastMessageContent'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      isGroupChat: data['isGroupChat'] ?? false, // Lee el campo isGroupChat
      groupName: data['groupName'], // Lee el nombre del grupo
      groupImageUrl: data['groupImageUrl'], // Lee la imagen del grupo
    );
  }

  // Método para convertir un ChatModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessageContent': lastMessageContent,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
    };
  }

  // Método copyWith para crear una copia modificada de un ChatModel (útil para actualizaciones inmutables)
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessageContent,
    Timestamp? lastMessageTimestamp,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }
}
