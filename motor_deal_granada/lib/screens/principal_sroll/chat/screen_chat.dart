import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de añadir intl en pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';
import 'personalizacion.dart';
import 'chat_edit.dart';

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
  bool _isAuthorized = true;

  String _chatDisplayName = 'Cargando...';
  String _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
  bool _isGroupChat = false;
  bool _favoriteDesign = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteDesign();
    _initializeChatDetails();
    _markMessagesAsRead();

    // Scroll to bottom on new message
    _scrollController.addListener(() {});
  }

  Future<void> _loadFavoriteDesign() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteDesign = prefs.getBool('favorite_design') ?? false;
    });
  }

  Future<void> _toggleFavoriteDesign() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteDesign = !_favoriteDesign;
      prefs.setBool('favorite_design', _favoriteDesign);
    });
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

      final chatDoc = await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final isGroup = data['isGroupChat'] ?? false;

        setState(() {
          _isGroupChat = isGroup;
        });

        if (isGroup) {
          setState(() {
            _chatDisplayName = data['groupName'] ?? 'Grupo Desconocido';
            _chatDisplayImageUrl =
                data['groupImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
          });
        } else {
          String? displayUid = widget.otherUserId;
          String? displayUserName = widget.otherUserName;
          String? displayImageUrl = widget.otherUserProfileImageUrl;

          if (displayUid != null &&
              displayUid.isNotEmpty &&
              (displayUserName == null || displayImageUrl == null)) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(displayUid)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              displayUserName =
                  userData['username'] ?? userData['email'] ?? 'Usuario';
              displayImageUrl =
                  userData['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
            }
          }

          setState(() {
            _chatDisplayName = displayUserName ?? 'Usuario';
            _chatDisplayImageUrl =
                displayImageUrl ?? 'https://i.imgur.com/BoN9kdC.png';
          });
        }
      }
    } catch (e) {
      setState(() {
        _chatDisplayName = 'Error';
        _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
      });
    }
  }

  Future<bool> _isUserConnected(String otherUserId) async {
    if (currentUser == null) return false;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
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

  Future<void> _confirmLeaveGroup() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text('¿Estás seguro de que deseas salir del grupo?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Salir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLeave != true || currentUser == null) return;

    try {
      final chatDocRef =
          FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

      await chatDocRef.update({
        'participants': FieldValue.arrayRemove([currentUser!.uid]),
      });

      Navigator.pop(context); // Salir del chat
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al salir del grupo: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _favoriteDesign ? const Color(0xFF1A0033) : Colors.black;
    final inputBgColor = _favoriteDesign ? const Color(0xFF2B004F) : Colors.grey[900];
    final messageMineColor = _favoriteDesign ? const Color(0xFF7F00FF) : Colors.purple;
    final messageOtherColor = _favoriteDesign ? const Color(0xFF3A1C71) : Colors.grey[800];
    final iconColor = _favoriteDesign ? Colors.amberAccent : Colors.purpleAccent;
    final textStyle = const TextStyle(fontFamily: 'Montserrat', color: Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(_chatDisplayImageUrl)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _chatDisplayName,
                style: textStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          if (_isGroupChat)
            IconButton(
              icon: Icon(Icons.exit_to_app, color: iconColor),
              tooltip: 'Salir del grupo',
              onPressed: _confirmLeaveGroup,
            ),
          IconButton(
            icon: Icon(
              _favoriteDesign ? Icons.brightness_3 : Icons.brightness_5,
              color: iconColor,
            ),
            onPressed: _toggleFavoriteDesign,
            tooltip: 'Cambiar diseño',
          ),
          IconButton(
            icon: Icon(Icons.palette, color: iconColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PersonalizacionScreen(),
                ),
              );
            },
            tooltip: 'Más opciones de personalización',
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
                  return const Center(
                    child: Text(
                      'Error al cargar mensajes',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }
                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                // Auto scroll al nuevo mensaje
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;

                    final type = messageData['type'] ?? 'text';

                    if (type == 'post') {
                      return buildSharedPostMessage(messageData, context);
                    }

                    final isMine = messageData['senderId'] == currentUser?.uid;

                    // Formatear hora
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(
                        crossAxisAlignment:
                            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMine ? messageMineColor : messageOtherColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                    Radius.circular(isMine ? 16 : 0),
                                bottomRight:
                                    Radius.circular(isMine ? 0 : 16),
                              ),
                            ),
                            child: Text(
                              messageData['content'] ?? '[Mensaje vacío]',
                              style: textStyle.copyWith(fontSize: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isMine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Text(
                                  formattedTime,
                                  style: textStyle.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isMine)
                                  Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: messageData['isRead'] == true
                                        ? Colors.blueAccent
                                        : Colors.white38,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              color: inputBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: textStyle,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: iconColor),
                    onPressed: _sendMessage,
                    tooltip: 'Enviar',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    try {
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

      // Opcional: marcar el chat para actualizar contadores de no leídos si usas eso
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatId)
          .update({
        'lastMessage': text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser!.uid,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  // Función para mostrar mensajes tipo 'post'
  Widget buildSharedPostMessage(Map<String, dynamic> data, BuildContext context) {
    final isMine = data['senderId'] == currentUser?.uid;

    final timestamp = data['timestamp'] as Timestamp?;
    final formattedTime = timestamp != null
        ? DateFormat('HH:mm').format(timestamp.toDate())
        : '';

    final imageUrl = data['imageUrl'] ?? '';
    final description = data['description'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isMine
                  ? (_favoriteDesign ? const Color(0xFF7F00FF) : Colors.purple)
                  : (_favoriteDesign ? const Color(0xFF3A1C71) : Colors.grey[800]),
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
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 150,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(width: 4),
                if (isMine)
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: data['isRead'] == true ? Colors.blueAccent : Colors.white38,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
