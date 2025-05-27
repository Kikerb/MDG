// lib/screens/chat/chat_details_screen.dart (Crea este nuevo archivo)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Opciones_chat_salir extends StatefulWidget {
  final String chatId;
  final bool isGroupChat;
  final String chatDisplayName;
  final String chatDisplayImageUrl;

  const Opciones_chat_salir({
    super.key,
    required this.chatId,
    required this.isGroupChat,
    required this.chatDisplayName,
    required this.chatDisplayImageUrl,
  });

  @override
  State<Opciones_chat_salir> createState() => _Opciones_chat_salir();
}

class _Opciones_chat_salir extends State<Opciones_chat_salir> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? groupCreatorId; // Para almacenar el UID del creador del grupo

  @override
  void initState() {
    super.initState();
    if (widget.isGroupChat) {
      _loadGroupCreator();
    }
  }

  Future<void> _loadGroupCreator() async {
    try {
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).get();
      if (chatDoc.exists) {
        setState(() {
          groupCreatorId = (chatDoc.data() as Map<String, dynamic>)['creatorId'];
        });
      }
    } catch (e) {
      print('Error al cargar creador del grupo: $e');
    }
  }

  // --- Función para salir del grupo ---
  Future<void> _leaveGroup() async {
    if (currentUser == null) return;

    // Confirmación al usuario
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Salir del Grupo', style: TextStyle(color: Colors.white)),
          content: const Text('¿Estás seguro de que quieres salir de este grupo?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.purpleAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salir', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        DocumentReference chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

        // Remover al usuario de la lista de participantes
        await chatDocRef.update({
          'participants': FieldValue.arrayRemove([currentUser!.uid]),
          'unreadCounts.${currentUser!.uid}': FieldValue.delete(), // Eliminar el contador de no leídos para este usuario
        });

        // Opcional: Añadir un mensaje al grupo de que el usuario ha salido
        await chatDocRef.collection('messages').add({
          'senderId': 'system', // O un ID especial para mensajes del sistema
          'content': '${currentUser!.displayName ?? currentUser!.email ?? "Un usuario"} ha salido del grupo.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
        });

        // Navegar de vuelta a la lista de chats o a la pantalla principal
        Navigator.of(context).popUntil((route) => route.isFirst); // Vuelve a la primera pantalla de la pila
      } catch (e) {
        print('Error al salir del grupo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al salir del grupo: $e')),
        );
      }
    }
  }

  // --- Función para eliminar el grupo (solo para el creador) ---
  Future<void> _deleteGroup() async {
    if (currentUser == null || groupCreatorId != currentUser!.uid) return; // Solo el creador puede eliminar

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Eliminar Grupo', style: TextStyle(color: Colors.white)),
          content: const Text('¿Estás seguro de que quieres eliminar este grupo permanentemente? Esta acción es irreversible.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.purpleAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        DocumentReference chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);

        // 1. Eliminar todos los mensajes de la subcolección
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          QuerySnapshot messagesSnapshot = await chatDocRef.collection('messages').get();
          for (DocumentSnapshot doc in messagesSnapshot.docs) {
            transaction.delete(doc.reference);
          }
        });

        // 2. Eliminar el documento principal del grupo
        await chatDocRef.delete();

        // Navegar de vuelta a la lista de chats o a la pantalla principal
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        print('Error al eliminar el grupo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el grupo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Detalles del Chat', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.chatDisplayImageUrl),
                radius: 60,
              ),
              const SizedBox(height: 20),
              Text(
                widget.chatDisplayName,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Solo muestra opciones si es un chat de grupo
              if (widget.isGroupChat) ...[
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.white70),
                  title: const Text('Miembros del Grupo', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // TODO: Navegar a una pantalla para ver la lista de miembros del grupo
                    // Podrías pasar widget.chatId a esa pantalla
                  },
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                  title: const Text('Salir del Grupo', style: TextStyle(color: Colors.redAccent)),
                  onTap: _leaveGroup,
                ),
                const Divider(color: Colors.grey),
                // Mostrar botón de eliminar solo si eres el creador
                if (groupCreatorId != null && currentUser != null && groupCreatorId == currentUser!.uid)
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Eliminar Grupo', style: TextStyle(color: Colors.red)),
                    onTap: _deleteGroup,
                  ),
              ] else ...[
                // Opciones para chat individual (si las hay)
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white70),
                  title: const Text('Ver perfil del usuario', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    // TODO: Navegar al perfil del otro usuario (usando widget.otherUserId)
                  },
                ),
                const Divider(color: Colors.grey),
                // Aquí podrías añadir opciones como "Bloquear usuario", "Silenciar", etc.
              ],
            ],
          ),
        ),
      ),
    );
  }
}