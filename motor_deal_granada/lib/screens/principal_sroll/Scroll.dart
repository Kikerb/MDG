import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../garage/public_garage_screen.dart';
import 'chat/chat_list_screen.dart' as cls;
import 'chat/contactos_chat.dart';
import 'chat/servicio_chat.dart' as cs;
import 'notificaciones/NotificationsScreen.dart';
import 'post/CommentsScreen.dart';
import 'post/Posts.dart';

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  State<ScrollScreen> createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  String? _currentUserId;
  int _currentIndex = 0;
  bool _showFolleto = false;

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
    }
  }

  Future<void> _addLoginNotification(String userId, String username) async {
    try {
      await FirebaseFirestore.instance.collection('Notifications').add({
        'userId': userId,
        'message': 'Sesión iniciada por $username',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al añadir notificación de inicio de sesión: $e');
    }
  }

  Future<void> _handleLike(String postId) async {
    if (_currentUserId == null) return;

    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      final docSnap = await docRef.get();
      if (!docSnap.exists) return;

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
    } catch (e) {
      print('Error actualizando likes: $e');
    }
  }

  void _handleComment(String postId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
    );

    if (result == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update(
        {'comments': FieldValue.increment(1)},
      );
    }
  }

  Future<void> _handleShare(String postId) async {
    try {
      final postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final data = postDoc.data()!;
      final description = data['description'] ?? '';
      final username = data['username'] ?? '';
      final imageUrl = data['imageUrl'] ?? '';
      final price = data['price'] as String?;
      final status = data['status'] as String?;

      final selectedChatId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => cls.ChatListScreen(
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.white),
            onPressed: () {
              setState(() => _showFolleto = true);
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
                return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay publicaciones aún.',
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

                  final likedUsers = List<String>.from(data['likedUsers'] ?? []);
                  final isLikedByCurrentUser = _currentUserId != null && likedUsers.contains(_currentUserId);

                  return PostCard(
                    postId: post.id,
                    username: data['username'] ?? 'Usuario',
                    imageUrl: data['imageUrl'] ?? '',
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
                    onUserTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PublicGarageScreen(userId: data['userId']),
                        ),
                      );
                    },
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactosChatScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.contacts, color: Colors.white, size: 32),
              ),
            ),
          ),
          if (_showFolleto)
            GestureDetector(
              onTap: () => setState(() => _showFolleto = false),
              child: Container(
                color: Colors.black54,
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/folleto.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => setState(() => _showFolleto = false),
                        child: const Icon(Icons.close, color: Colors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
