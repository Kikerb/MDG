import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personalizacion.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId;
  final String? otherUserName;
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

  bool _isGroupChat = false;
  String _chatDisplayName = 'Cargando...';
  String _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';

  Color chatBackground = Colors.black;
  Color myMessageColor = Colors.purple;
  Color otherMessageColor = Colors.grey[800]!;
  double fontSize = 14;

  @override
  void initState() {
    super.initState();
    _loadFavoriteDesign();
    _initializeChatDetails();
    _markMessagesAsRead();
  }

  Future<void> _loadFavoriteDesign() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      chatBackground = Color(prefs.getInt('chatBackground') ?? Colors.black.value);
      myMessageColor = Color(prefs.getInt('myMessageColor') ?? Colors.purple.value);
      otherMessageColor = Color(prefs.getInt('otherMessageColor') ?? Colors.grey[800]!.value);
      fontSize = prefs.getDouble('fontSize') ?? 14;
    });
  }

  Future<void> _initializeChatDetails() async {
    final chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      final isGroup = data['isGroupChat'] ?? false;
      setState(() {
        _isGroupChat = isGroup;
        _chatDisplayName = isGroup ? data['groupName'] ?? 'Grupo' : widget.otherUserName ?? 'Usuario';
        _chatDisplayImageUrl = isGroup ? data['groupImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png' : widget.otherUserProfileImageUrl ?? 'https://i.imgur.com/BoN9kdC.png';
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;
    final docRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(currentUser!.uid)) {
        await docRef.update({'unreadCounts.${currentUser!.uid}': 0});
      }
    }
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final message = {
      'content': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'text',
    };

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('messages')
        .add(message);

    _messageController.clear();
    _scrollToBottom();

    await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).update({
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': currentUser!.uid,
    });
  }

  Widget _buildMessage(Map<String, dynamic> messageData) {
    final isMine = messageData['senderId'] == currentUser?.uid;
    final timestamp = messageData['timestamp'] as Timestamp?;
    final formattedTime = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';
    final type = messageData['type'] ?? 'text';

    if (type == 'post') {
      final imageUrl = messageData['imageUrl'] ?? '';
      final description = messageData['description'] ?? '';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMine ? myMessageColor : otherMessageColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                          height: 150,
                          child: Center(child: Icon(Icons.broken_image, size: 50)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: fontSize, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(
                formattedTime,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? myMessageColor : otherMessageColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                messageData['content'] ?? '',
                style: TextStyle(color: Colors.white, fontSize: fontSize),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(
                formattedTime,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: chatBackground,
      appBar: AppBar(
        backgroundColor: chatBackground,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(_chatDisplayImageUrl)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _chatDisplayName,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalizacionScreen()),
              ).then((updated) {
                if (updated == true) {
                  _loadFavoriteDesign();
                }
              });
            },
            tooltip: 'Personalización',
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    return _buildMessage(messageData);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.white, fontSize: fontSize),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
