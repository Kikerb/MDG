import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSelectionScreen extends StatelessWidget {
  const ChatSelectionScreen({Key? key}) : super(key: key);

  // Extensión para simular firstWhereOrNull (opcional, si la necesitas)
  T? firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (var element in list) {
      if (test(element)) return element;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Selecciona un chat'),
        ),
        body: const Center(
          child: Text('No has iniciado sesión.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes chats'));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data()! as Map<String, dynamic>;

              final participants = List<String>.from(chatData['participants'] ?? []);
              final isGroupChat = chatData['isGroupChat'] ?? false;

              String displayName = 'Chat sin nombre';
              String displayImageUrl = 'https://i.imgur.com/BoN9kdC.png';

              if (isGroupChat) {
                displayName = chatData['groupName'] ?? 'Grupo sin nombre';
                displayImageUrl = chatData['groupImageUrl'] ?? displayImageUrl;

                // Renderiza directamente el ListTile para grupo
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(displayImageUrl),
                    radius: 22,
                  ),
                  title: Text(displayName),
                  onTap: () {
                    Navigator.of(context).pop(chatDoc.id);
                  },
                );
              } else {
                // Chat individual: hay que obtener el UID del otro usuario
                final otherUserId = participants.firstWhere((uid) => uid != currentUser.uid, orElse: () => '');

                if (otherUserId.isEmpty) {
                  // Si no hay otro usuario, no mostramos este chat
                  return const SizedBox.shrink();
                }

                // FutureBuilder para obtener datos del otro usuario
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Cargando...'),
                      );
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(displayImageUrl),
                          radius: 22,
                        ),
                        title: const Text('Usuario desconocido'),
                        onTap: () {
                          Navigator.of(context).pop(chatDoc.id);
                        },
                      );
                    }

                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                    displayName = userData['username'] ?? userData['email'] ?? 'Usuario sin nombre';
                    displayImageUrl = userData['profileImageUrl'] ?? displayImageUrl;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(displayImageUrl),
                        radius: 22,
                      ),
                      title: Text(displayName),
                      onTap: () {
                        Navigator.of(context).pop(chatDoc.id);
                      },
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}
