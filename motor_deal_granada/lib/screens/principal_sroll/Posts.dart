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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Ajuste de margen para un mejor espaciado
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Bordes redondeados para la tarjeta
      elevation: 5, // Sombra para la tarjeta
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Ajuste de padding interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showUsername)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Espacio debajo del nombre de usuario
                child: Row(
                  children: [
                    const CircleAvatar(
                      // Puedes poner una imagen de perfil del usuario aquí
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1A0033)), // Color del icono a juego con el fondo de la tarjeta
                    ),
                    const SizedBox(width: 12), // Mayor espacio entre avatar y nombre
                    Expanded( // Permite que el texto del nombre de usuario ocupe el espacio restante
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16.0, // Tamaño de fuente ligeramente mayor
                        ),
                        overflow: TextOverflow.ellipsis, // Para manejar nombres de usuario largos
                      ),
                    ),
                  ],
                ),
              ),
            // Imagen del post
            ClipRRect( // Recorta la imagen con bordes redondeados
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220, // Altura ligeramente mayor para la imagen
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800], // Color de fondo más oscuro para el error
                    height: 220,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white, size: 40), // Icono de error
                          SizedBox(height: 8),
                          Text(
                            'Error al cargar imagen',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12), // Más espacio después de la imagen
            // Descripción del post
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 15.0), // Tamaño de fuente ajustado
              maxLines: 3, // Limita la descripción a 3 líneas
              overflow: TextOverflow.ellipsis, // Añade puntos suspensivos si el texto es muy largo
            ),
            // botón "Ver más" para descripciones largas si lo deseas
             if (description.length > 70) // Puedes ajustar esta condición
               Align(
                 alignment: Alignment.bottomRight,
                 child: TextButton(
                   onPressed: () {
                     // Implementar la lógica para expandir la descripción
                     // Por ejemplo, mostrar un diálogo con la descripción completa
                   },
                   child: const Text(
                     'Ver más',
                     style: TextStyle(color: Colors.purpleAccent, fontSize: 13),
                   ),
                 ),
               ),
            const SizedBox(height: 8),

            // Mostrar precio y estado solo si showPrice y showStatus son true y los datos existen
            if (showPrice && price != null && price!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Precio: $price',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent, // Tono de verde más brillante
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ),
            if (showStatus && status != null && status!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Estado: $status',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent, // Tono de azul más brillante
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ),
            
            if (showActions)
              Column( // Usamos Column para separar las acciones del contador
                children: [
                  const Divider(color: Colors.white12, height: 20), // Separador visual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.redAccent : Colors.white70, // Tono de rojo y blanco ajustado
                        onPressed: onLike,
                        label: '$likes',
                      ),
                      _buildActionButton(
                        icon: Icons.comment,
                        color: Colors.white70,
                        onPressed: onComment,
                        label: '$comments',
                      ),
                      if (onShare != null) // Solo muestra el botón si onShare no es null
                        _buildActionButton(
                          icon: Icons.share,
                          color: Colors.white70,
                          onPressed: onShare, // Aquí onShare ya no es null por la verificación anterior
                          label: '$shares',
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper method para construir los botones de acción para reducir la duplicación de código
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed, // <--- CAMBIO CLAVE AQUÍ: Acepta VoidCallback?
    required String label,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 24), // Tamaño de icono ajustado
          onPressed: onPressed, // onPressed aquí puede ser null, lo cual es manejado por IconButton
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13), // Tamaño de fuente para el contador
        ),
      ],
    );
  }
}