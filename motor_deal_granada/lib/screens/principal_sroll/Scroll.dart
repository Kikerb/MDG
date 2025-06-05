import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart'; // Correcto
import '../../widgets/bottom_navigation_bar.dart';
import 'chat/chat_list_screen.dart' as cls;
import 'chat/contactos_chat.dart';
import 'chat/servicio_chat.dart' as cs;
import 'notificaciones/NotificationsScreen.dart'; // Correcto
import 'post/CommentsScreen.dart'; // Correcto
import 'post/Posts.dart'; // Correcto, ya que Posts.dart está en el mismo directorio
class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  State<ScrollScreen> createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  String? _currentUserId; // Variable privada para usuario actual
  int _currentIndex = 0; // Índice para navegación

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      _addLoginNotification(user.uid, user.email ?? 'Usuario');
    } else {
      print('Usuario no logueado al iniciar ScrollScreen. Algunas funcionalidades pueden estar limitadas.');
    }
  }

  Future<void> _addLoginNotification(String userId, String username) async {
    try {
      await FirebaseFirestore.instance.collection('Notifications').add({
        'userId': userId,
        'message': 'Sesión iniciada por $username',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Notificación de inicio de sesión añadida.');
    } catch (e) {
      print('Error al añadir notificación de inicio de sesión: $e');
    }
  }

  Future<void> _handleLike(String postId) async {
    if (_currentUserId == null) {
      print('Error: _currentUserId es null. El usuario no está logueado para dar like.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para dar like.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        print('Documento $postId no existe');
        return;
      }

      final postData = docSnap.data();
      final List<String> likedUsers = List<String>.from(postData?['likedUsers'] ?? []);
      int likes = postData?['likes'] ?? 0;

      if (likedUsers.contains(_currentUserId)) {
        likedUsers.remove(_currentUserId);
        likes = (likes > 0) ? likes - 1 : 0;
      } else {
        likedUsers.add(_currentUserId!);
        likes += 1;
      }

      await docRef.update({'likedUsers': likedUsers, 'likes': likes});
      print('Like/Unlike actualizado para post: $postId, likes: $likes');
    } catch (e) {
      print('Error actualizando likes para post $postId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el like: $e')),
      );
    }
  }

  void _handleComment(String postId) async {
    print('Abriendo comentarios para post: $postId');

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'comments': FieldValue.increment(1),
        });
        print('Contador de comentarios incrementado para post $postId');
      } catch (e) {
        print('Error al actualizar contador de comentarios: $e');
      }
    }
  }

  Future<void> _sendPostToChat({
    required String chatId,
    required String postId,
    required String username,
    required String imageUrl,
    required String description,
    String? price,
    String? status,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final messageData = {
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'shared_post',
      'content': {
        'postId': postId,
        'username': username,
        'imageUrl': imageUrl,
        'description': description,
        'price': price,
        'status': status,
      },
      'readBy': [],
    };

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chatMessages')
        .add(messageData);
  }

  Future<void> _handleShare(String postId) async {
    try {
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        print('No existe el post con id $postId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el post para compartir')),
        );
        return;
      }

      final data = postDoc.data()!;

      final description = data['description'] ?? 'Publicación sin descripción';
      final username = data['username'] ?? 'Usuario Desconocido';
      final imageUrl = data['imageUrl'] ?? 'https://via.placeholder.com/150/000000/FFFFFF?text=No+Image';
      final price = data['price'] as String?;
      final status = data['status'] as String?;

      // Selecciona chat
      final selectedChatId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => cls.ChatListScreen(   // Alias cls para chat_list_screen.dart
            postToShare: {
              'postId': postId,
              'description': description,
              'username': username,
              'imageUrl': imageUrl,
              'price': price ?? '',
              'status': status ?? '',
            },
          ),
        ),
      );

      if (selectedChatId != null) {
        await cs.ChatService.sharePostToChat(
          chatId: selectedChatId,
          postId: postId,
          username: username,
          imageUrl: imageUrl,
          description: description,
          price: price,
          status: status,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post compartido en el chat')),
        );
      }
    } catch (e) {
      print('Error al compartir post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'MotorDeal Granada',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            print('Navegando a NotificationsScreen');
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.article, color: Colors.white),
            onPressed: () {
              print('Navegando a NoticiasScreen');
              Navigator.of(context).pushNamed(noticiasScreenRoute);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo Noticias')),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                );
              }

              if (snapshot.hasError) {
                print('StreamBuilder Error: ${snapshot.error}');
                return Center(
                  child: Text(
                    'Error al cargar los posts: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay publicaciones aún. ¡Sé el primero en publicar algo!',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final posts = snapshot.data!.docs;

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final data = post.data()! as Map<String, dynamic>;

                  final List<String> likedUsers =
                      List<String>.from(data['likedUsers'] ?? []);

                  final bool isLikedByCurrentUser =
                      _currentUserId != null && likedUsers.contains(_currentUserId);

                  return PostCard(
                    postId: post.id,
                    username: data['username'] ?? 'Usuario Desconocido',
                    imageUrl: data['imageUrl'] ??
                        'https://via.placeholder.com/150/000000/FFFFFF?text=No+Image',
                    likes: data['likes'] ?? 0,
                    comments: data['comments'] ?? 0,
                    shares: data['shares'] ?? 0,
                    description: data['description'] ?? '',
                    isLiked: isLikedByCurrentUser,
                    onLike: () => _handleLike(post.id),
                    onComment: () => _handleComment(post.id),
                    onShare: () => _handleShare(post.id),

                    showActions: true,
                    showPrice: false,
                    showStatus: false,
                    showUsername: true,
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: GestureDetector(
              onTap: () {
                print('Navegando a ChatListScreen.');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ContactosChatScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.contacts, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
