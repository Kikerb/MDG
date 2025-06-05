import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/chat_model.dart';
import 'screen_chat.dart';
import 'create_group.dart';

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

    final nonNullCurrentUser = currentUser!; // variable local no nula

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

          final List<ChatModel> chats = chatListSnapshot.data!.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();

          return Column(
            children: [
              // Barra pequeña mostrando el post que se va a compartir
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
                    String displayName;
                    String displayImageUrl;
                    String targetUserId = '';

                    if (chat.isGroupChat) {
                      displayName = chat.groupName ?? 'Grupo Desconocido';
                      displayImageUrl = chat.groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png';

                      return _buildSelectableChatListItem(
                        chat: chat,
                        displayName: displayName,
                        displayImageUrl: displayImageUrl,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              selectedChatIds.add(chat.id);
                            } else {
                              selectedChatIds.remove(chat.id);
                            }
                          });
                        },
                        isSelected: selectedChatIds.contains(chat.id),
                      );
                    } else {
                      targetUserId = chat.participants.firstWhere((uid) => uid != nonNullCurrentUser.uid, orElse: () => '');
                      if (targetUserId.isEmpty) return const SizedBox.shrink();

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(targetUserId).get(),
                        builder: (context, snapshot) {
                          String otherUserName = 'Usuario Desconocido';
                          String otherUserProfileImageUrl = 'https://i.imgur.com/BoN9kdC.png';

                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            otherUserName = data['username'] ?? data['email'] ?? otherUserName;
                            otherUserProfileImageUrl = data['profileImageUrl'] ?? otherUserProfileImageUrl;
                          }

                          return _buildSelectableChatListItem(
                            chat: chat,
                            displayName: otherUserName,
                            displayImageUrl: otherUserProfileImageUrl,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedChatIds.add(chat.id);
                                } else {
                                  selectedChatIds.remove(chat.id);
                                }
                              });
                            },
                            isSelected: selectedChatIds.contains(chat.id),
                          );
                        },
                      );
                    }
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

  Widget _buildSelectableChatListItem({
    required ChatModel chat,
    required String displayName,
    required String displayImageUrl,
    required ValueChanged<bool?> onChanged,
    required bool isSelected,
  }) {
    final nonNullCurrentUser = currentUser!;
    final unreadCount = chat.unreadCounts[nonNullCurrentUser.uid] ?? 0;
    final subtitleColor = unreadCount > 0 ? Colors.lightBlueAccent : Colors.white70;
    final lastMessageContent = chat.lastMessageContent.isEmpty
        ? 'Toca para iniciar una conversación.'
        : chat.lastMessageContent;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        activeColor: Colors.purpleAccent,
        checkColor: Colors.white,
        secondary: CircleAvatar(
          backgroundImage: NetworkImage(displayImageUrl),
          radius: 22,
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
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Future<void> _sharePostToSelectedChats() async {
    if (widget.postToShare == null || currentUser == null) return;

    final nonNullCurrentUser = currentUser!;
    final post = widget.postToShare!;
    final batch = FirebaseFirestore.instance.batch();
    final now = Timestamp.now();

    for (final chatId in selectedChatIds) {
      final messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chats')
          .doc();

      batch.set(messageRef, {
        'type': 'post',
        'postId': post['postId'],
        'imageUrl': post['imageUrl'],
        'description': post['description'],
        'price': post['price'],
        'status': post['status'],
        'senderId': nonNullCurrentUser.uid,
        'timestamp': now,
      });

      final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(chatId);
      batch.update(chatDocRef, {
        'lastMessageContent': '[Post compartido]',
        'lastMessageTimestamp': now,
      });
    }

    await batch.commit();

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
