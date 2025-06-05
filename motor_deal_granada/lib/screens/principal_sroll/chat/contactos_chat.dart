import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/chat_model.dart';
import 'create_group.dart';
import 'screen_chat.dart';

class ContactosChatScreen extends StatefulWidget {
  const ContactosChatScreen({super.key});

  @override
  State<ContactosChatScreen> createState() => _ContactosChatScreenState();
}

class _ContactosChatScreenState extends State<ContactosChatScreen> {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: nonNullCurrentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, chatListSnapshot) {
          if (chatListSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
          }
          if (chatListSnapshot.hasError) {
            return Center(
              child: Text('Error: ${chatListSnapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          if (!chatListSnapshot.hasData || chatListSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tienes chats activos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          final List<ChatModel> chats = chatListSnapshot.data!.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              String displayName;
              String displayImageUrl;
              String targetUserId = '';

              if (chat.isGroupChat) {
                displayName = chat.groupName ?? 'Grupo Desconocido';
                displayImageUrl = chat.groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png';

                return _buildChatListItem(
                  chat: chat,
                  displayName: displayName,
                  displayImageUrl: displayImageUrl,
                );
              } else {
                targetUserId = chat.participants.firstWhere(
                  (uid) => uid != nonNullCurrentUser.uid,
                  orElse: () => '',
                );
                if (targetUserId.isEmpty) return const SizedBox.shrink();

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
                  builder: (context, snapshot) {
                    String otherUserName = 'Usuario Desconocido';
                    String otherUserProfileImageUrl = 'https://i.imgur.com/BoN9kdC.png';

                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      otherUserName = data['username'] ?? data['email'] ?? otherUserName;
                      otherUserProfileImageUrl = data['profileImageUrl'] ?? otherUserProfileImageUrl;
                    }

                    return _buildChatListItem(
                      chat: chat,
                      displayName: otherUserName,
                      displayImageUrl: otherUserProfileImageUrl,
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

  String _getLastMessagePreview(ChatModel chat) {
    if (chat.lastMessageType == 'shared_post' && chat.lastMessageContent is Map) {
      final content = chat.lastMessageContent as Map<String, dynamic>;
      final description = content['description'] ?? 'Post compartido';
      return '📌 $description';
    }

    if (chat.lastMessageContent is String) {
      return (chat.lastMessageContent as String).isEmpty
          ? 'Toca para iniciar una conversación.'
          : chat.lastMessageContent as String;
    }

    return 'Mensaje no reconocido';
  }

  Widget _buildChatListItem({
    required ChatModel chat,
    required String displayName,
    required String displayImageUrl,
  }) {
    final nonNullCurrentUser = currentUser!;
    final unreadCount = chat.unreadCounts[nonNullCurrentUser.uid] ?? 0;
    final subtitleColor = unreadCount > 0 ? Colors.lightBlueAccent : Colors.white70;
    final lastMessagePreview = _getLastMessagePreview(chat);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chat.id,
                otherUserId: chat.isGroupChat
                    ? null
                    : chat.participants.firstWhere(
                        (uid) => uid != nonNullCurrentUser.uid,
                        orElse: () => '',
                      ),
                otherUserName: chat.isGroupChat ? chat.groupName : null,
                otherUserProfileImageUrl: chat.isGroupChat ? chat.groupImageUrl : null,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundImage: NetworkImage(displayImageUrl),
          radius: 22,
        ),
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          lastMessagePreview,
          style: TextStyle(
            color: subtitleColor,
            fontStyle: unreadCount > 0 ? FontStyle.italic : FontStyle.normal,
          ),
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
      ),
    );
  }
}
