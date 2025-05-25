import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/Posts.dart';
import '../../main.dart';
import 'CommentsScreen.dart';
import 'NotificationsScreen.dart';
import '../../widgets/bottom_navigation_bar.dart';

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  State<ScrollScreen> createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  bool _defaultPostInserted = false;
  String? currentUserId;
  int _currentIndex = 0; // Índice inicial para Inicio (0)

  @override
  void initState() {
    super.initState();
    _insertDefaultPost();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      _addLoginNotification(user.uid, user.email ?? 'Usuario');
    }
  }

  Future<void> _addLoginNotification(String userId, String username) async {
    await FirebaseFirestore.instance.collection('Notifications').add({
      'userId': userId,
      'message': 'Sesión iniciada por $username',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _insertDefaultPost() async {
    if (_defaultPostInserted) return;

    final postsSnapshot =
        await FirebaseFirestore.instance.collection('Posts').limit(1).get();

    if (postsSnapshot.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('Posts').add({
        'username': 'Admin',
        'imageUrl': 'https://i.ytimg.com/vi/lZmrRlYNCbM/maxresdefault.jpg',
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'description': 'Este es el post por defecto de MotorDeal Granada.',
        'timestamp': FieldValue.serverTimestamp(),
        'likedUsers': [],
      });
    }

    _defaultPostInserted = true;
  }

  Future<void> _handleLike(String postId, Map<String, dynamic> data) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('Posts').doc(postId);

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        print('Documento $postId no existe');
        return;
      }

      final data = docSnap.data();
      final likedUsers = data != null && data.containsKey('likedUsers')
          ? List<String>.from(data['likedUsers'])
          : <String>[];
      int likes = docSnap['likes'] ?? 0;

      if (likedUsers.contains(userId)) {
        likedUsers.remove(userId);
        likes = (likes > 0) ? likes - 1 : 0;
      } else {
        likedUsers.add(userId);
        likes += 1;
      }

      await docRef.update({'likedUsers': likedUsers, 'likes': likes});
      setState(() {});
    } catch (e) {
      print('Error actualizando likes: $e');
    }
  }

  void _handleComment(String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
    );
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.article, color: Colors.white),
            onPressed: () {
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
                .collection('Posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error al cargar los posts. Inténtalo de nuevo.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: Colors.purpleAccent),
                );
              }

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay publicaciones aún.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final data = post.data()! as Map<String, dynamic>;

                  final List<dynamic> likedUsers =
                      List<dynamic>.from(data['likedUsers'] ?? []);
                  final isLiked = currentUserId != null &&
                      likedUsers.contains(currentUserId);

                  return PostCard(
                    postId: post.id,
                    username: data['username'] ?? 'Usuario Desconocido',
                    imageUrl: data['imageUrl'] ??
                        'https://via.placeholder.com/150',
                    likes: data['likes'] ?? 0,
                    comments: data['comments'] ?? 0,
                    shares: data['shares'] ?? 0,
                    description: data['description'] ?? '',
                    isLiked: isLiked,
                    onLike: () => _handleLike(post.id, data),
                    onComment: () => _handleComment(post.id),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Abrir contactos (futuro comportamiento)')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.contacts,
                    color: Colors.white, size: 32),
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