import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/Posts.dart'; // Asumo que este archivo contiene tu widget PostCard
import '../../widgets/bottom_navigation_bar.dart'; // <--- ¡NUEVA IMPORTACIÓN!

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  State<ScrollScreen> createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  int _currentIndex = 0; // Índice inicial para Inicio (0)

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abriendo Notificaciones')),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abriendo Mensajes')),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error al cargar posts: ${snapshot.error}');
            return const Center(
              child: Text(
                'Error al cargar los posts. Inténtalo de nuevo.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
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
              final data = post.data() as Map<String, dynamic>;

              return PostCard(
                username: data['username'] ?? 'Usuario Desconocido',
                imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
                likes: data['likes'] ?? 0,
                comments: data['comments'] ?? 0,
                shares: data['shares'] ?? 0,
                description: data['description'] ?? '',
              );
            },
          );
        },
      ),

      bottomNavigationBar: CustomBottomNavigationBar( // <--- ¡USANDO EL WIDGET PERSONALIZADO!
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index; // Actualiza el índice seleccionado
          });
          // La navegación se maneja dentro de CustomBottomNavigationBar
        },
      ),
    );
  }
}