import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Posts.dart'; // Asumo que este archivo contiene tu widget PostCard

class ScrollScreen extends StatelessWidget { // <--- ¡Importante! Aquí se resuelve el conflicto y se usa 'ScrollScreen'
  const ScrollScreen({super.key}); // <--- El constructor debe ser const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'), // <--- Texto en español y const
        backgroundColor: Colors.black, // Color de fondo para la AppBar
        foregroundColor: Colors.white, // Color del texto del título
      ),
      backgroundColor: Colors.black, // Color de fondo para el Scaffold
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Si hay un error en la carga de datos
          if (snapshot.hasError) {
            print('Error al cargar posts: ${snapshot.error}'); // Opcional: logear el error para depuración
            return const Center( // <--- Añadido const
              child: Text(
                'Error al cargar los posts. Inténtalo de nuevo.', // Texto en español
                style: TextStyle(color: Colors.white), // Color del texto
              ),
            );
          }

          // Si los datos aún están cargando
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator()); // <--- Añadido const
          }

          // Si llegamos aquí, significa que no hay errores y tenemos datos.
          final posts = snapshot.data!.docs;

          // Si no hay posts disponibles
          if (posts.isEmpty) {
            return const Center( // <--- Añadido const
              child: Text(
                'No hay publicaciones aún.', // Texto en español
                style: TextStyle(color: Colors.white), // Color del texto
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // Usamos 'as Map<String, dynamic>' y luego acceso seguro con '??'
              final data = post.data() as Map<String, dynamic>;

              return PostCard(
                username: data['username'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                likes: data['likes'] ?? 0,
                comments: data['comments'] ?? 0,
                shares: data['shares'] ?? 0,
                description: data['description'] ?? '',
                // Es una buena práctica pasar el ID del documento si lo necesitas,
                // aunque no lo usas en PostCard actualmente. Podrías añadirlo:
                // id: post.id,
              );
            },
          );
        },
      ),
    );
  }
}