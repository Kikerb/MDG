import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }
          if (userSnapshot.hasError) {
            return Center(
              child: Text('Error al cargar datos del usuario: ${userSnapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(
              child: Text('Datos de usuario no encontrados.', style: TextStyle(color: Colors.white)),
            );
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final List<String> following = List<String>.from(userData?['following'] ?? []);
          final List<String> followers = List<String>.from(userData?['followers'] ?? []);

          // *******************************************************************
          // CAMBIO CLAVE AQUÍ: Filtrar solo usuarios que se siguen mutuamente
          // *******************************************************************
          final Set<String> relevantUserIds = {};
          // Convertir ambas listas a Sets para usar la intersección
          final Set<String> followingSet = following.toSet();
          final Set<String> followersSet = followers.toSet();

          // Encontrar los UIDs que están en AMBAS listas (intersección)
          final Set<String> mutualFollowers = followingSet.intersection(followersSet);

          // Agregar los mutuos seguidores a relevantUserIds
          for (var id in mutualFollowers) {
            relevantUserIds.add(id);
          }
          // *******************************************************************
          // FIN DEL CAMBIO CLAVE
          // *******************************************************************

          // Excluir el propio UID del usuario de la lista de IDs relevantes
          relevantUserIds.remove(currentUser!.uid);

          if (relevantUserIds.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tienes chats activos. Solo puedes chatear con usuarios que te siguen y tú también sigues.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          final List<String> uniqueRelevantUserIds = relevantUserIds.toList();

          return ListView.builder(
            itemCount: uniqueRelevantUserIds.length,
            itemBuilder: (context, index) {
              final String otherUserId = uniqueRelevantUserIds[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, otherUserSnapshot) {
                  String otherUserName = 'Usuario Desconocido';
                  String otherUserEmail = '';
                  String otherUserProfileImageUrl = 'https://i.imgur.com/BoN9kdC.png';

                  if (otherUserSnapshot.connectionState == ConnectionState.done &&
                      otherUserSnapshot.hasData && otherUserSnapshot.data!.exists) {
                    final otherUserData = otherUserSnapshot.data!.data() as Map<String, dynamic>;
                    otherUserName = otherUserData['username'] ?? otherUserData['email'] ?? 'Usuario Desconocido';
                    otherUserEmail = otherUserData['email'] ?? '';
                    otherUserProfileImageUrl = otherUserData['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
                  } else if (otherUserSnapshot.hasError) {
                    print('Error fetching other user data: ${otherUserSnapshot.error}');
                  }

                  List<String> sortedIds = [currentUser!.uid, otherUserId]..sort();
                  final String chatId = 'chat_${sortedIds[0]}_${sortedIds[1]}';

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('messages').doc(chatId).snapshots(),
                    builder: (context, chatDocSnapshot) {
                      ChatModel? chat;
                      String lastMessageContent = 'Toca para iniciar una conversación.';
                      int unreadCount = 0;
                      Color subtitleColor = Colors.white70;

                      if (chatDocSnapshot.connectionState == ConnectionState.active &&
                          chatDocSnapshot.hasData && chatDocSnapshot.data!.exists) {
                        chat = ChatModel.fromFirestore(chatDocSnapshot.data!);
                        lastMessageContent = chat!.lastMessageContent.isEmpty ? 'Toca para iniciar una conversación.' : chat.lastMessageContent;
                        unreadCount = chat.unreadCounts[currentUser!.uid] ?? 0;
                        if (unreadCount > 0) {
                          subtitleColor = Colors.lightBlueAccent;
                        }
                      }

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(otherUserProfileImageUrl),
                            radius: 25,
                          ),
                          title: Text(
                            otherUserName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessageContent,
                            style: TextStyle(color: subtitleColor, fontStyle: unreadCount > 0 ? FontStyle.italic : FontStyle.normal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chatId,
                                  otherUserId: otherUserId,
                                  otherUserName: otherUserName,
                                  otherUserEmail: otherUserEmail,
                                  otherUserProfileImageUrl: otherUserProfileImageUrl,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}