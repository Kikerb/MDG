import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Importa Provider
import 'chat_edit.dart'; // Importa la pantalla de edición y el ChatThemeProvider

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String otherUserProfileImageUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    required this.otherUserProfileImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Marca los mensajes como leídos y resetea el contador de no leídos
  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;

    // Reiniciar el contador de no leídos para el usuario actual en la cabecera del chat
    // Usa `set` con `merge: true` para crear el documento si no existe, o actualizarlo
    await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).set(
      {
        'unreadCounts': {
          currentUser!.uid: 0,
        },
        'participants': [currentUser!.uid, widget.otherUserId], // Asegúrate de que los participantes estén presentes
      },
      SetOptions(merge: true), // Esto es crucial para no sobrescribir el documento si ya existe
    );
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
      // 1. Asegurarse de que el documento de la cabecera del chat exista.
      // Se utiliza `set` con `SetOptions(merge: true)` para crear el documento
      // si no existe, o simplemente actualizarlo si ya lo hace, sin borrar otros campos.
      await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).set(
        {
          'participants': [currentUser!.uid, widget.otherUserId],
          'lastMessageContent': messageContent,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser!.uid,
          // Inicializar los contadores si el chat es nuevo, o actualizarlos
          'unreadCounts': {
            currentUser!.uid: 0, // El remitente siempre tiene 0 no leídos de lo que envía
            widget.otherUserId: FieldValue.increment(1), // Incrementa para el receptor
          }
        },
        SetOptions(merge: true), // Importante para no sobrescribir todo el documento
      );

      // 2. Añadir el mensaje a la subcolección de mensajes
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      // Mueve el scroll al final de la lista de mensajes (después de enviar)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    // Obtén el proveedor de tema
    final chatThemeProvider = Provider.of<ChatThemeProvider>(context);

    // Widget para el fondo del chat
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
        gradient = const LinearGradient(colors: [Colors.black87, Colors.grey]); // Fallback para degradados
      }
      backgroundWidget = Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
      );
    } else if (chatThemeProvider.chatBackground == 'default') {
      backgroundWidget = Container(color: Colors.black); // Fondo negro por defecto
    } else {
      // Aquí podrías añadir lógica para imágenes de fondo si las incluyes en chat_edit.dart
      backgroundWidget = Container(color: Colors.black); // Fallback para otros tipos de fondo
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
              backgroundImage: NetworkImage(widget.otherUserProfileImageUrl),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded( // Usa Expanded para que el texto no desborde
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Para manejar nombres largos
                  ),
                  Text(
                    widget.otherUserEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton( // BOTÓN PARA IR A LA PANTALLA DE PERSONALIZACIÓN
            icon: const Icon(Icons.palette, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatEditScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack( // Usa un Stack para poner el fondo detrás de los mensajes
        children: [
          backgroundWidget, // Tu fondo aquí
          Column( // El resto de tu contenido de chat
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
                              // Aplica el color de burbuja guardado del ChatThemeProvider
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
                              style: TextStyle(color: chatThemeProvider.chatTextColor), // Aplica el color de texto
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