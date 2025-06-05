import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id; // ID del documento de la conversación (ej., "chat_uid1_uid2")
  final List<String> participants; // UIDs de los participantes
  final dynamic lastMessageContent; // Contenido del último mensaje (String o Map para post compartido)
  final String lastMessageType; // 'text', 'shared_post', etc.
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
    required this.lastMessageType,
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
      lastMessageContent: data['lastMessageContent'],
      lastMessageType: data['lastMessageType'] ?? 'text',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      isGroupChat: data['isGroupChat'] ?? false,
      groupName: data['groupName'],
      groupImageUrl: data['groupImageUrl'],
    );
  }

  // Método para convertir un ChatModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessageContent': lastMessageContent,
      'lastMessageType': lastMessageType,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
    };
  }

  // Método copyWith para crear una copia modificada de un ChatModel (útil para actualizaciones inmutables)
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    dynamic lastMessageContent,
    String? lastMessageType,
    Timestamp? lastMessageTimestamp,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    bool? isGroupChat,
    String? groupName,
    String? groupImageUrl,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
    );
  }
}
