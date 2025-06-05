import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../post/CompartirInputScreen.dart' as compartirInputScreen;
import 'chat_edit.dart';
import 'opciones_chat_salir.dart'; // Verifica que la ruta sea correcta

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

  // Variables para mostrar en AppBar
  String _chatDisplayName = 'Cargando...';
  String _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png';
  bool _isGroupChat = false; // <-- Agregado para controlar si es grupo o no

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

  Future<bool> _isUserConnected(String otherUserId) async {
    if (currentUser == null) return false;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;

    List<dynamic> followers = data['followers'] ?? [];
    List<dynamic> following = data['following'] ?? [];

    // Retorna true si otherUserId está en followers o following
    return followers.contains(otherUserId) || following.contains(otherUserId);
  }

  // Inicializa nombre, imagen y si es grupo o no
  Future<void> _initializeChatDetails() async {
    try {
      if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
        bool isConnected = await _isUserConnected(widget.otherUserId!);
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

      DocumentSnapshot chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        bool isGroup = data['isGroupChat'] ?? false;

        setState(() {
          _isGroupChat = isGroup; // Guardamos si es grupo o no
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

          if (displayUid != null &&
              displayUid.isNotEmpty &&
              (displayUserName == null || displayImageUrl == null)) {
            DocumentSnapshot userDoc =
                await FirebaseFirestore.instance.collection('users').doc(displayUid).get();
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

  // Marca los mensajes como leídos y resetea contador
  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;

    DocumentReference chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

    DocumentSnapshot chatDoc = await chatDocRef.get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(data['participants'] ?? []);

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
    final String messageContent = _messageController.text.trim();
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
      DocumentReference chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

      DocumentSnapshot chatDoc = await chatDocRef.get();
      List<String> currentParticipants = [];
      bool isGroupChat = false;

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        currentParticipants = List<String>.from(data['participants'] ?? []);
        isGroupChat = data['isGroupChat'] ?? false;
      } else {
        print("Advertencia: El documento de chat ${widget.chatId} no existe al enviar un mensaje.");
        currentParticipants =
            (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) ? [currentUser!.uid, widget.otherUserId!] : [currentUser!.uid];
      }

      Map<String, dynamic> updateData = {
        'lastMessageContent': messageContent,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      };

      Map<String, int> unreadCounts = {};
      for (String participantId in currentParticipants) {
        if (participantId != currentUser!.uid) {
          unreadCounts[participantId] =
              (chatDoc.exists ? (chatDoc.get('unreadCounts.${participantId}') ?? 0) : 0) + 1;
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

  @override
  Widget build(BuildContext context) {
    final chatThemeProvider = Provider.of<ChatThemeProvider>(context);

    Widget backgroundWidget;
    if (chatThemeProvider.chatBackground.startsWith('gradient_')) {
      Gradient gradient;
      switch (chatThemeProvider.chatBackground) {
        case 'gradient_blue':
          gradient = const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          break;
        case 'gradient_green':
          gradient = const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          break;
        case 'gradient_purple':
          gradient = const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFFAB47BC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
          break;
        default:
          gradient = const LinearGradient(colors: [Colors.black87, Colors.grey]);
      }
      backgroundWidget = Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      backgroundWidget = Container(color: Colors.black);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_chatDisplayImageUrl),
              radius: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _chatDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          if (_isAuthorized) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatEditScreen(
                      chatId: widget.chatId,
                      otherUserId: widget.otherUserId,
                      otherUserName: _chatDisplayName,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          backgroundWidget,
          Column(
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

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay mensajes aún',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final messageData = message.data() as Map<String, dynamic>;
                        final isMe = messageData['senderId'] == currentUser!.uid;

                        return Container(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blueAccent : Colors.grey[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              messageData['content'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black54,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje',
                          hintStyle: TextStyle(color: Colors.white70),
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
            ],
          ),
        ],
      ),
    );
  }
}

class ChatThemeProvider with ChangeNotifier {
  String _chatBackground = 'gradient_blue';

  String get chatBackground => _chatBackground;

  set chatBackground(String value) {
    _chatBackground = value;
    notifyListeners();
  }
}
