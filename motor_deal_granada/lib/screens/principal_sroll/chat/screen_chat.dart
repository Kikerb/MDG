// chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_edit.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId; // Será nulo/vacío si es un grupo
  final String? otherUserName; // Nombre del grupo o del otro usuario
  final String? otherUserEmail; // Email del otro usuario, no para grupos
  final String? otherUserProfileImageUrl; // URL imagen grupo o usuario

  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUserId,
    this.otherUserName,
    this.otherUserEmail,
    this.otherUserProfileImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAuthorized = true;

  String _chatDisplayName = 'Cargando...';
  String _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
  bool _isGroupChat = false;

  // Estado para modo diseño "favorito"
  bool _favoriteDesign = false;

  @override
  void initState() {
    super.initState();
    _initializeChatDetails();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatDetails() async {
    try {
      if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
        final isConnected = await _isUserConnected(widget.otherUserId!);
        setState(() {
          _isAuthorized = isConnected;
        });
        if (!isConnected) {
          setState(() {
            _chatDisplayName = 'No autorizado';
            _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
          });
          return;
        }
      }

      final chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final isGroup = data['isGroupChat'] ?? false;

        setState(() {
          _isGroupChat = isGroup;
        });

        if (isGroup) {
          setState(() {
            _chatDisplayName = data['groupName'] ?? 'Grupo Desconocido';
            _chatDisplayImageUrl = data['groupImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
          });
        } else {
          String? displayUid = widget.otherUserId;
          String? displayUserName = widget.otherUserName;
          String? displayImageUrl = widget.otherUserProfileImageUrl;

          if (displayUid != null && displayUid.isNotEmpty && (displayUserName == null || displayImageUrl == null)) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(displayUid).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              displayUserName = userData['username'] ?? userData['email'] ?? 'Usuario Desconocido';
              displayImageUrl = userData['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
            }
          }

          setState(() {
            _chatDisplayName = displayUserName ?? 'Usuario';
            _chatDisplayImageUrl = displayImageUrl ?? 'https://i.imgur.com/BoN9kdC.png';
          });
        }
      }
    } catch (e) {
      print('Error al cargar detalles del chat en ChatScreen: $e');
      setState(() {
        _chatDisplayName = 'Error';
        _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
      });
    }
  }

  Future<bool> _isUserConnected(String otherUserId) async {
    if (currentUser == null) return false;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;
    final followers = data['followers'] ?? [];
    final following = data['following'] ?? [];

    return followers.contains(otherUserId) || following.contains(otherUserId);
  }

  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;

    final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

    final chatDoc = await chatDocRef.get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);

      if (participants.contains(currentUser!.uid)) {
        await chatDocRef.update({'unreadCounts.${currentUser!.uid}': 0});
      }
    }
  }

  Future<void> _sendMessage() async {
    if (!_isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes enviar mensajes a este usuario')),
      );
      return;
    }

    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    _messageController.clear();

    final messageData = {
      'senderId': currentUser!.uid,
      'content': messageContent,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'isRead': false,
    };

    try {
      final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

      final chatDoc = await chatDocRef.get();

      List<String> currentParticipants = [];
      bool isGroupChat = false;

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        currentParticipants = List<String>.from(data['participants'] ?? []);
        isGroupChat = data['isGroupChat'] ?? false;
      } else {
        currentParticipants =
            (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) ? [currentUser!.uid, widget.otherUserId!] : [currentUser!.uid];
      }

      final updateData = {
        'lastMessageContent': messageContent,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      };

      final unreadCounts = <String, int>{};
      for (var participantId in currentParticipants) {
        if (participantId != currentUser!.uid) {
          unreadCounts[participantId] = (chatDoc.exists ? (chatDoc.get('unreadCounts.$participantId') ?? 0) : 0) + 1;
        } else {
          unreadCounts[participantId] = 0;
        }
      }
      updateData['unreadCounts'] = unreadCounts;

      if (!isGroupChat && !chatDoc.exists) {
        updateData['participants'] = currentParticipants;
        updateData['isGroupChat'] = false;
      }

      await chatDocRef.set(updateData, SetOptions(merge: true));
      await chatDocRef.collection('messages').add(messageData);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error al enviar mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar mensaje: $e')));
    }
  }

  Future<void> _sendPost(Map<String, dynamic> postData) async {
    if (!_isAuthorized || currentUser == null) return;

    final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);
    final chatDoc = await chatDocRef.get();

    List<String> currentParticipants = [];
    bool isGroupChat = false;

    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      currentParticipants = List<String>.from(data['participants'] ?? []);
      isGroupChat = data['isGroupChat'] ?? false;
    } else {
      currentParticipants = (widget.otherUserId != null && widget.otherUserId!.isNotEmpty)
          ? [currentUser!.uid, widget.otherUserId!]
          : [currentUser!.uid];
    }

    final messageData = {
      'senderId': currentUser!.uid,
      'type': 'post',
      'postData': postData,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    final updateData = {
      'lastMessageContent': '[Post compartido]',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUser!.uid,
    };

    final unreadCounts = <String, int>{};
    for (var participantId in currentParticipants) {
      if (participantId != currentUser!.uid) {
        unreadCounts[participantId] = (chatDoc.exists ? (chatDoc.get('unreadCounts.$participantId') ?? 0) : 0) + 1;
      } else {
        unreadCounts[participantId] = 0;
      }
    }
    updateData['unreadCounts'] = unreadCounts;

    if (!isGroupChat && !chatDoc.exists) {
      updateData['participants'] = currentParticipants;
      updateData['isGroupChat'] = false;
    }

    await chatDocRef.set(updateData, SetOptions(merge: true));
    await chatDocRef.collection('messages').add(messageData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _favoriteDesign ? Colors.deepPurple[900] : Colors.black;
    final inputBgColor = _favoriteDesign ? Colors.deepPurple[800] : Colors.grey[900];
    final messageMineColor = _favoriteDesign ? Colors.purpleAccent : Colors.purple;
    final messageOtherColor = Colors.grey[800];
    final iconColor = Colors.purpleAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_chatDisplayImageUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _chatDisplayName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_favoriteDesign ? Icons.star : Icons.star_border, color: iconColor),
            onPressed: () {
              setState(() {
                _favoriteDesign = !_favoriteDesign;
              });
            },
            tooltip: 'Cambiar diseño',
          ),
          IconButton(
            icon: Icon(Icons.edit, color: iconColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatId: widget.chatId),
                ),
              );
            },
            tooltip: 'Editar chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar mensajes', style: TextStyle(color: Colors.white70)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                }
                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text('No hay mensajes', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data()! as Map<String, dynamic>;

                    if (messageData['type'] == 'post') {
                      return _buildSharedPost(messageData['postData'], messageData['senderId'] == currentUser?.uid);
                    } else {
                      return _buildTextMessage(messageData, messageMineColor, messageOtherColor);
                    }
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: inputBgColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    cursorColor: Colors.purpleAccent,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: iconColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(Map<String, dynamic> message, Color messageMineColor, Color? messageOtherColor) {
    final isMine = message['senderId'] == currentUser?.uid;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? messageMineColor : messageOtherColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['content'] ?? '',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSharedPost(Map<String, dynamic> postData, bool isMine) {
    return Container(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.deepPurpleAccent : Colors.deepPurple[400],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            postData['title'] ?? 'Post sin título',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            postData['content'] ?? 'Sin contenido',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (postData['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(postData['imageUrl'], width: 150, height: 150, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }
}
