import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'chat_edit.dart';
import 'opciones_chat_salir.dart'; // Asegúrate de que esta ruta sea correcta
// Asumiendo que tienes un ChatThemeProvider definido en alguna parte de tu proyecto
// import 'package:your_app_name/providers/chat_theme_provider.dart'; // <--- Descomenta y ajusta si es necesario
import 'chat_principal.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId; // Será nulo/vacío si es un grupo
  final String? otherUserName; // Puede ser el nombre del grupo o el nombre del otro usuario
  final String? otherUserEmail; // Puede ser el email del otro usuario, no aplica para grupos
  final String? otherUserProfileImageUrl; // Puede ser la URL de la imagen del grupo o del otro usuario

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

  // Variables para almacenar el nombre y la imagen que se mostrarán en la AppBar
  String _chatDisplayName = 'Cargando...';
  String _chatDisplayImageUrl = 'https://i.imgur.com/BoN9kdC.png'; // Imagen por defecto

  @override
  void initState() {
    super.initState();
    _initializeChatDetails(); // Carga los detalles del chat al iniciar
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Método para inicializar el nombre y la imagen del chat
  Future<void> _initializeChatDetails() async {
    try {
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        bool isGroup = data['isGroupChat'] ?? false;

        if (isGroup) {
          // Si es un chat de grupo
          setState(() {
            _chatDisplayName = data['groupName'] ?? 'Grupo Desconocido';
            _chatDisplayImageUrl = data['groupImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';
          });
        } else {
          // Si es un chat individual
          // Usamos los datos pasados por widget si están disponibles, si no, los cargamos
          String? displayUid = widget.otherUserId;
          String? displayUserName = widget.otherUserName;
          String? displayImageUrl = widget.otherUserProfileImageUrl;

          // Si el UID del otro usuario es válido y no tenemos el nombre/imagen
          if (displayUid != null && displayUid.isNotEmpty && (displayUserName == null || displayImageUrl == null)) {
            DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(displayUid).get();
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

  // Marca los mensajes como leídos y resetea el contador de no leídos
  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;

    DocumentReference chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

    DocumentSnapshot chatDoc = await chatDocRef.get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(data['participants'] ?? []);

      if (participants.contains(currentUser!.uid)) {
        await chatDocRef.update(
          {
            'unreadCounts.${currentUser!.uid}': 0,
          },
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final String messageContent = _messageController.text.trim();
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
        currentParticipants = (widget.otherUserId != null && widget.otherUserId!.isNotEmpty)
            ? [currentUser!.uid, widget.otherUserId!]
            : [currentUser!.uid];
      }

      Map<String, dynamic> updateData = {
        'lastMessageContent': messageContent,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      };

      Map<String, int> unreadCounts = {};
      for (String participantId in currentParticipants) {
        if (participantId != currentUser!.uid) {
          unreadCounts[participantId] = (chatDoc.exists ? (chatDoc.get('unreadCounts.${participantId}') ?? 0) : 0) + 1;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asegúrate de que ChatThemeProvider esté correctamente importado y proporcionado
    // Puedes tener algo como:
    // `ChangeNotifierProvider(create: (_) => ChatThemeProvider(), child: MyApp())`
    // en tu main.dart o en un nivel superior.
    final chatThemeProvider = Provider.of<ChatThemeProvider>(context);

    Widget backgroundWidget;
    if (chatThemeProvider.chatBackground.startsWith('gradient_')) {
      Gradient gradient;
      if (chatThemeProvider.chatBackground == 'gradient_blue') {
        gradient = const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
      } else if (chatThemeProvider.chatBackground == 'gradient_green') {
        gradient = const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
      } else if (chatThemeProvider.chatBackground == 'gradient_purple') {
        gradient = const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFFAB47BC)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
      } else {
        gradient = const LinearGradient(colors: [Colors.black87, Colors.grey]);
      }
      backgroundWidget = Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
      );
    } else if (chatThemeProvider.chatBackground == 'default') {
      backgroundWidget = Container(color: Colors.black);
    } else {
      backgroundWidget = Container(color: Colors.black);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Esto simplemente vuelve a la pantalla anterior (la lista de chats)
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_chatDisplayImageUrl),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatDisplayName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.otherUserEmail != null && widget.otherUserEmail!.isNotEmpty && (widget.otherUserId != null && widget.otherUserId!.isNotEmpty))
                    Text(
                      widget.otherUserEmail!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón para ir a la pantalla de personalización
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatEditScreen()),
              );
            },
          ),
          // Botón para ir a la pantalla de detalles del chat (información del grupo/usuario)
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () async {
              // Obtener la información del chat para pasarla a ChatDetailsScreen
              DocumentSnapshot chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();
              bool isGroup = (chatDoc.data() as Map<String, dynamic>)['isGroupChat'] ?? false;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Opciones_chat_salir( // Aquí se usa el nombre original que tenías
                    chatId: widget.chatId,
                    isGroupChat: isGroup,
                    chatDisplayName: _chatDisplayName, // Usa la variable de estado ya cargada
                    chatDisplayImageUrl: _chatDisplayImageUrl, // Usa la variable de estado ya cargada
                  ),
                ),
              );
            },
          ),
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
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Di algo para empezar la conversación!', style: TextStyle(color: Colors.white70)));
                    }

                    final List<DocumentSnapshot> messageDocs = snapshot.data!.docs.reversed.toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients && _scrollController.position.pixels != _scrollController.position.maxScrollExtent) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messageDocs.length,
                      itemBuilder: (context, index) {
                        final messageData = messageDocs[index].data() as Map<String, dynamic>;
                        final bool isMe = messageData['senderId'] == currentUser!.uid;
                        final String messageContent = messageData['content'] ?? '';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? chatThemeProvider.chatBubbleColor : chatThemeProvider.chatOtherBubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isMe ? 12 : 0),
                                topRight: Radius.circular(isMe ? 0 : 12),
                                bottomLeft: const Radius.circular(12),
                                bottomRight: const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              messageContent,
                              style: TextStyle(color: chatThemeProvider.chatTextColor),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _sendMessage,
                      backgroundColor: Colors.purpleAccent,
                      mini: true,
                      child: const Icon(Icons.send, color: Colors.white),
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