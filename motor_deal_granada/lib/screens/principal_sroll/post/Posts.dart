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
  final VoidCallback? onShare;

  final String? price;
  final String? status;
  final bool showPrice;
  final bool showStatus;
  final bool showActions;
  final bool showUsername;

  final VoidCallback? onUserTap;

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
    this.onShare,
    this.price,
    this.status,
    this.showPrice = false,
    this.showStatus = false,
    this.showActions = true,
    this.showUsername = true,
    this.onUserTap, // 👈 Asignado en el constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A0033),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showUsername)
              GestureDetector(
                onTap: onUserTap,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 22,
                      child: Icon(Icons.person, color: Color(0xFF1A0033)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 17.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Imagen del post
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 230,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    height: 230,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white, size: 40),
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

            const SizedBox(height: 12),

            // Descripción del post
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 15.0),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            if (description.length > 70)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Lógica opcional para ver más
                  },
                  child: const Text(
                    'Ver más',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Precio y estado (Garage)
            if (showPrice && price != null && price!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Precio: $price',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ),
            if (showStatus && status != null && status!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Estado: $status',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ),

            if (showActions)
              Column(
                children: [
                  const Divider(color: Colors.white12, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.redAccent : Colors.white70,
                        onPressed: onLike,
                        label: '$likes',
                      ),
                      _buildActionButton(
                        icon: Icons.comment,
                        color: Colors.white70,
                        onPressed: onComment,
                        label: '$comments',
                      ),
                      if (onShare != null)
                        _buildActionButton(
                          icon: Icons.share,
                          color: Colors.white70,
                          onPressed: onShare,
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}