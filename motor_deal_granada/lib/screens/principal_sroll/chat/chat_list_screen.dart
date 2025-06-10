// Modificamos la clase ChatListScreen con los cambios solicitados
// - Arreglamos el nombre de la subcolección de mensajes ('chat' en vez de 'chats')
// - Aumentamos el contador de compartidos en el post
// - Se muestra visualmente el post compartido en el chat
// - Permite al receptor pulsar para ver el post
// - Integración en ChatScreen del renderizado del post compartido

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/chat_model.dart';
import 'screen_chat.dart';
import 'create_group.dart';

class ChatListScreen extends StatefulWidget {
  final Map<String, dynamic>? postToShare;

  const ChatListScreen({super.key, this.postToShare});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Set<String> selectedChatIds = {};

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Debes iniciar sesión para ver tus chats.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final nonNullCurrentUser = currentUser!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: nonNullCurrentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, chatListSnapshot) {
          if (!chatListSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<ChatModel> chats = chatListSnapshot.data!.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();

          return Column(
            children: [
              if (widget.postToShare != null)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (widget.postToShare!['imageUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.postToShare!['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compartiendo este post:\n${widget.postToShare!['description'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecciona chats para compartir:',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final displayName = chat.isGroupChat
                        ? chat.groupName ?? 'Grupo'
                        : 'Usuario';
                    final displayImageUrl = chat.isGroupChat
                        ? chat.groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png'
                        : 'https://i.imgur.com/BoN9kdC.png';

                    return CheckboxListTile(
                      value: selectedChatIds.contains(chat.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            selectedChatIds.add(chat.id);
                          } else {
                            selectedChatIds.remove(chat.id);
                          }
                        });
                      },
                      title: Text(displayName, style: const TextStyle(color: Colors.white)),
                      secondary: CircleAvatar(backgroundImage: NetworkImage(displayImageUrl)),
                      checkColor: Colors.white,
                      activeColor: Colors.purpleAccent,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: widget.postToShare != null && selectedChatIds.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Colors.purpleAccent,
              child: const Icon(Icons.send),
              onPressed: _sharePostToSelectedChats,
            )
          : null,
    );
  }

 Future<void> _sharePostToSelectedChats() async {
  if (widget.postToShare == null || currentUser == null) return;

  final post = widget.postToShare!;
  final now = Timestamp.now();

  // En lugar de usar un batch, lo hacemos individual para asegurar que todo se ejecuta bien por separado.
  for (final chatId in selectedChatIds) {
    final messageRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chat') // Asegúrate que esta sea tu subcolección correcta
        .doc();

    await messageRef.set({
      'type': 'post',
      'postId': post['postId'],
      'imageUrl': post['imageUrl'],
      'description': post['description'],
      'price': post['price'],
      'status': post['status'],
      'senderId': currentUser!.uid,
      'timestamp': now,
    });

    final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(chatId);
    await chatDocRef.update({
      'lastMessageContent': '[Post compartido]',
      'lastMessageTimestamp': now,
    });
  }

  // ✅ Incrementa contador correctamente
  final postId = post['postId'];
  if (postId != null) {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({'sharesCount': FieldValue.increment(1)});
  }

  if (!mounted) return;
  Navigator.of(context).pop();
}

}

// Widget para visualizar mensajes de tipo post
Widget buildSharedPostMessage(Map<String, dynamic> data, BuildContext context) {
  return GestureDetector(
    onTap: () {
      final postId = data['postId'];
      if (postId != null) {
        Navigator.pushNamed(context, '/post_detail', arguments: postId);
      }
    },
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                data['imageUrl'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            data['description'] ?? 'Sin descripción',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Precio: \$${data['price'] ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// Luego, dentro de ChatScreen > _buildMessageItem:
//   if (data['type'] == 'post') {
//     return buildSharedPostMessage(data, context);
//   }
// Asegúrate de tener esa lógica en tu método para renderizar mensajes del chat.
