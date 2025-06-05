import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/chat_model.dart';
import 'screen_chat.dart';
import 'create_group.dart';
import 'chat_list_screen.dart';

// Extensión para List para simular .firstWhereOrNull
// Flutter 3.10+ ya lo tiene, pero si usas una versión anterior, esto es útil.
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

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
      body: StreamBuilder<QuerySnapshot>(
        // Escucha todos los documentos en la colección 'messages'
        // donde el array 'participants' contiene el UID del usuario actual.
        // Esto incluirá tanto chats individuales como grupales que el usuario sea miembro.
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: currentUser!.uid)
            .orderBy('lastMessageTimestamp', descending: true) // Ordenar por actividad reciente
            .snapshots(),
        builder: (context, chatListSnapshot) {
          if (chatListSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }
          if (chatListSnapshot.hasError) {
            print('Error al cargar chats: ${chatListSnapshot.error}');
            return Center(
              child: Text('Error al cargar chats: ${chatListSnapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          if (!chatListSnapshot.hasData || chatListSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tienes chats activos. Crea un nuevo grupo o chatea con usuarios que te siguen y tú también sigues.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          // Filtra los chats individuales (por si hay duplicados o lógica antigua)
          // y procesa tanto chats individuales como grupales.
          final List<ChatModel> chats = chatListSnapshot.data!.docs.map((doc) {
            return ChatModel.fromFirestore(doc);
          }).toList();

          // Aquí podrías ordenar los chats si quieres alguna prioridad (ej. no leídos primero)
          // chats.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp)); // Ya ordenado por la query

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              String displayName;
              String displayImageUrl;
              String targetUserId = ''; // Solo relevante para chats individuales

              // Determinar si es un chat de grupo o un chat individual
              if (chat.isGroupChat) {
                // Es un chat de grupo
                displayName = chat.groupName ?? 'Grupo Desconocido';
                displayImageUrl = chat.groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png'; // Imagen por defecto para grupos
                // No hay otherUserId para grupos, pasaremos el chatId como tal a la pantalla de chat
              } else {
                // Es un chat individual
                // Encontrar el UID del otro participante
                targetUserId = chat.participants.firstWhere(
                  (uid) => uid != currentUser!.uid,
                  orElse: () => '', // Si por alguna razón no se encuentra, default a vacío
                );

                // Si no hay otro usuario, no se debe mostrar este chat
                if (targetUserId.isEmpty) {
                  return const SizedBox.shrink(); // No muestra este elemento
                }

                // Usamos un FutureBuilder para obtener los detalles del otro usuario
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
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
                    }

                    // Ahora construye el ListTile para el chat individual
                    return _buildChatListItem(
                      chat: chat,
                      displayName: otherUserName,
                      displayImageUrl: otherUserProfileImageUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chat.id,
                              otherUserId: targetUserId, // Pasa el UID del otro usuario para chat individual
                              otherUserName: otherUserName,
                              otherUserEmail: otherUserEmail,
                              otherUserProfileImageUrl: otherUserProfileImageUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }

              // Si es un chat de grupo, o un chat individual donde no necesitamos el FutureBuilder (ya sabemos los datos)
              return _buildChatListItem(
                chat: chat,
                displayName: displayName,
                displayImageUrl: displayImageUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chat.id,
                        // Para grupos, no hay 'otherUserId', pasamos el chatId como tal
                        // En ChatScreen, deberás manejar si es un chat individual o grupal
                        otherUserId: targetUserId, // Será vacío si es un grupo, pero lo pasamos para consistencia
                        otherUserName: displayName, // Nombre del grupo
                        otherUserEmail: '', // No aplica para grupos
                        otherUserProfileImageUrl: displayImageUrl, // Imagen del grupo
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Widget auxiliar para construir el ListTile común a ambos tipos de chat
  Widget _buildChatListItem({
    required ChatModel chat,
    required String displayName,
    required String displayImageUrl,
    required VoidCallback onTap,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    String lastMessageContent = chat.lastMessageContent.isEmpty ? 'Toca para iniciar una conversación.' : chat.lastMessageContent;
    int unreadCount = chat.unreadCounts[currentUser!.uid] ?? 0;
    Color subtitleColor = Colors.white70;

    if (unreadCount > 0) {
      subtitleColor = Colors.lightBlueAccent;
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(displayImageUrl),
          radius: 25,
        ),
        title: Text(
          displayName,
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
        onTap: onTap,
      ),
    );
  }
}