// lib/screens/principal_sroll/Posts.dart

import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String username;
  final String imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final String description;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onShare; // Hacemos onShare opcional (nullable)

  // Nuevas propiedades para GARAGE
  final String? price; // Puede ser null si no aplica
  final String? status; // Puede ser null si no aplica
  final bool showPrice; // Controla si se muestra el precio
  final bool showStatus; // Controla si se muestra el estado

  // Propiedades existentes para controlar la visibilidad
  final bool showActions;
  final bool showUsername;

  const PostCard({
    super.key,
    required this.postId,
    required this.username,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.description,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    this.onShare, // Debe estar en el constructor

    // Nuevas propiedades para Garage
    this.price,
    this.status,
    this.showPrice = false, // Por defecto, no mostrar precio
    this.showStatus = false, // Por defecto, no mostrar estado

    // Propiedades existentes
    this.showActions = true,
    this.showUsername = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A0033), // Fondo de la tarjeta púrpura oscuro
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showUsername)
              Row(
                children: [
                  const CircleAvatar(
                    // Puedes poner una imagen de perfil del usuario aquí
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Imagen del post
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey,
                  height: 200,
                  child: const Center(
                    child: Text(
                      'Error al cargar imagen',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Descripción del post
            Text(
              description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),

            // Mostrar precio y estado solo si showPrice y showStatus son true y los datos existen
            if (showPrice && price != null && price!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Precio: $price',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (showStatus && status != null && status!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Estado: $status',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (showActions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: onLike,
                  ),
                  Text('$likes', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.white),
                    onPressed: onComment,
                  ),
                  Text('$comments', style: const TextStyle(color: Colors.white)),
                  if (onShare != null) // Solo muestra el botón si onShare no es null
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: onShare,
                    ),
                  Text('$shares', style: const TextStyle(color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}