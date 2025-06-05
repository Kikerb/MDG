import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId; // Null if group chat
  final String? otherUserName; // Group or user name
  final String? otherUserEmail;
  final String? otherUserProfileImageUrl;

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

  // Diseño favorito
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

    return followers.contains(otherUserId) && following.contains(otherUserId);
  }

  void _markMessagesAsRead() async {
    if (currentUser == null) return;

    final chatRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);
    await chatRef.update({
      'unreadCounts.${currentUser!.uid}': 0,
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (currentUser == null) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

    final newMessage = {
      'senderId': currentUser!.uid,
      'content': messageContent,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('chat')
        .add(newMessage);

    // Actualizar el último mensaje en el documento principal del chat
    await chatRef.update({
      'lastMessageContent': messageContent,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      // Actualizar los contadores de mensajes no leídos para otros participantes
      'unreadCounts': FieldValue.arrayUnion([]), // Aquí personalizar según lógica de tu app
    });

    // Desplazar hacia abajo para ver el mensaje enviado
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessageItem(DocumentSnapshot messageDoc) {
    final data = messageDoc.data() as Map<String, dynamic>;
    final senderId = data['senderId'] ?? '';
    final content = data['content'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;

    final isCurrentUser = senderId == currentUser?.uid;

    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 50 : 10,
        right: isCurrentUser ? 10 : 50,
        top: 5,
        bottom: 5,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blueAccent : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          if (timestamp != null)
            Text(
              TimeOfDay.fromDateTime(timestamp.toDate()).format(context),
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(_chatDisplayName),
          centerTitle: true,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'No estás autorizado para chatear con este usuario.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_chatDisplayImageUrl),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _chatDisplayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.chatId)
                  .collection('chat')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes. ¡Empieza la conversación!',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
