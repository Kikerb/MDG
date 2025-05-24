import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

import 'Posts.dart'; // Asumo que este archivo contiene tu widget PostCard

class ScrollScreen extends StatelessWidget {
  const ScrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para toda la pantalla

      appBar: AppBar(
        backgroundColor: Colors.black, // Fondo negro para la AppBar
        elevation: 0, // Sin sombra
        title: const Text(
          'MotorDeal Granada', // Título central como en la imagen o el logo
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true, // Centra el título en la AppBar
        leading: IconButton(
          // Botón de Notificaciones (izquierda)
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            // Lógica para ir a la pantalla de notificaciones
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abriendo Notificaciones')),
            );
          },
        ),
        actions: [
          IconButton(
            // Botón de Mensajes (derecha)
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

      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Posts')
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ); // Color del indicador
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

              // Usa containsKey para verificar que exista la clave antes de usarla
              final username =
                  data.containsKey('username')
                      ? data['username']
                      : 'Usuario Desconocido';
              final imageUrl =
                  data.containsKey('imageUrl')
                      ? data['imageUrl']
                      : 'https://via.placeholder.com/150';
              final likes = data.containsKey('likes') ? data['likes'] : 0;
              final comments =
                  data.containsKey('comments') ? data['comments'] : 0;
              final shares = data.containsKey('shares') ? data['shares'] : 0;
              final description =
                  data.containsKey('description') ? data['description'] : '';

              return PostCard(
                username: username,
                imageUrl: imageUrl,
                likes: likes,
                comments: comments,
                shares: shares,
                description: description,
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(
          0xFF1A0033,
        ), // Fondo de la barra púrpura oscuro
        selectedItemColor: Colors.purpleAccent, // Color del icono seleccionado
        unselectedItemColor: Colors.white, // Color del icono no seleccionado
        currentIndex:
            0, // Puedes manejar el estado de la navegación con un StatefulWidget
        onTap: (index) {
          // Lógica para navegar entre secciones
          String message = '';
          switch (index) {
            case 0:
              message = 'Inicio'; // Ya estamos aquí
              break;
            case 1:
              message = 'Buscar';
              Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
              break;
            case 2:
              message = 'Garage';
              Navigator.of(context).pushReplacementNamed(garageScreenRoute);
              break;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Has seleccionado: $message')));
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio', // Texto en español
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), // Icono de lupa
            label: 'Buscar', // Texto en español
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse), // O un icono que represente un garaje
            label: 'Garage', // Texto en español
          ),
        ],
      ),
    );
  }
}
