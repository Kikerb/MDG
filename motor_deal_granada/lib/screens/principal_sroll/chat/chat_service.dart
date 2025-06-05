import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static Future<void> sharePostToChat({
    required String chatId,
    required String postId,
    required String username,
    required String imageUrl,
    required String description,
    String? price,
    String? status,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageData = {
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'shared_post',
      'content': {
        'postId': postId,
        'username': username,
        'imageUrl': imageUrl,
        'description': description,
        'price': price,
        'status': status,
      },
      'readBy': [],
    };

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chatMessages')
        .add(messageData);
  }
}
