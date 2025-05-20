import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Posts.dart'; // Asumo que este archivo contiene tu widget PostCard

class Scroll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inicio')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // --- CAMBIO APLICADO AQUÍ: Manejo de errores ---
          if (snapshot.hasError) {
            // Si hay un error, mostramos un mensaje al usuario.
            print('Error al cargar posts: ${snapshot.error}'); // Opcional: logear el error
            return Center(
              child: Text('Error al cargar los posts. Inténtalo de nuevo.'),
            );
          }
          // --- FIN DEL CAMBIO ---

          // Si no hay error, verificamos si los datos están cargando o aún no llegan.
          if (!snapshot.hasData) {
            // Opcionalmente, podrías usar snapshot.connectionState == ConnectionState.waiting aquí también.
            return Center(child: CircularProgressIndicator());
          }

          // Si llegamos aquí, significa que no hay errores y tenemos datos.
          final posts = snapshot.data!.docs;
          

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
