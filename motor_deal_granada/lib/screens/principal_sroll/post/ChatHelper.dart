//Lógica de compartir post integrada directamente en una clase existente (por ejemplo, ChatScreen o una clase de helpers)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHelper {
  static Future<void> sharePostToChat({
    required String receiverId,
    required String postId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Obtener datos del post desde Firestore
    final postSnap = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    if (!postSnap.exists) return;
    final postData = postSnap.data()!;

    final imageUrl = postData['imageUrl'] ?? '';
    final description = postData['description'] ?? '';

    // Generar chatId
    final chatIdList = [currentUser.uid, receiverId]..sort();
    final chatId = chatIdList.join("_");

    final message = {
      'senderId': currentUser.uid,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'post',
      'postId': postId,
      'imageUrl': imageUrl,
      'description': description,
    };

    // Guardar mensaje en la colección de mensajes
    final chatRef = FirebaseFirestore.instance
      .collection('messages')
      .doc(chatId)
      .collection('messages');

    await chatRef.add(message);

    // Actualizar resumen del chat
    await FirebaseFirestore.instance.collection('messages').doc(chatId).set({
      'lastMessage': '[Post compartido]',
      'lastMessageSender': currentUser.uid,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Incrementar el contador de "shares" del post
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'shares': FieldValue.increment(1),
    });
  }
}
