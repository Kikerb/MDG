// Correcciones para el funcionamiento de compartir posts

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompartirScreen extends StatelessWidget {
  final String shareText;
  final String shareUrl;
  final String postId; // Añadimos el postId para actualizar el contador

  const CompartirScreen({
    Key? key,
    required this.shareText,
    required this.shareUrl,
    required this.postId,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> _getMutualFollowers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];

    final follows = await FirebaseFirestore.instance
        .collection('followers')
        .doc(currentUserId)
        .collection('following')
        .get();

    List<Map<String, dynamic>> mutuals = [];

    for (var doc in follows.docs) {
      final followedId = doc.id;

      final isFollowingBack = await FirebaseFirestore.instance
          .collection('followers')
          .doc(followedId)
          .collection('following')
          .doc(currentUserId)
          .get();

      if (isFollowingBack.exists) {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(followedId)
            .get();
        if (userSnap.exists) {
          mutuals.add({
            'userId': followedId,
            'username': userSnap['username'],
            'profileImage': userSnap['profileImage'] ?? '',
          });
        }
      }
    }

    return mutuals;
  }

  Future<void> _sendPostToChat(BuildContext context, String receiverId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = [currentUser.uid, receiverId]..sort();
    final chatDocId = chatId.join("_");

    final message = {
      'senderId': currentUser.uid,
      'receiverId': receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'post',
      'imageUrl': shareUrl,
      'description': shareText,
    };

    final chatMessagesRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(chatDocId)
        .collection('messages');

    await chatMessagesRef.add(message);

    await FirebaseFirestore.instance.collection('messages').doc(chatDocId).set({
      'lastMessage': '[Post compartido]',
      'lastMessageSender': currentUser.uid,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'shares': FieldValue.increment(1),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post compartido con éxito')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir con...'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getMutualFollowers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No tienes amistades mutuas aún.', style: TextStyle(color: Colors.white70)),
            );
          }

          final mutuals = snapshot.data!;

          return ListView.builder(
            itemCount: mutuals.length,
            itemBuilder: (context, index) {
              final user = mutuals[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['profileImage'] ?? ''),
                  backgroundColor: Colors.grey,
                ),
                title: Text(user['username'], style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await _sendPostToChat(context, user['userId']);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
