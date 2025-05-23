import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String username;
  final String imageUrl;
  final String description;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked; // <-- nuevo
  final VoidCallback onLike;
  final VoidCallback onComment;

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
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(username),
            leading: const Icon(Icons.account_circle),
          ),
          Image.network(imageUrl, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                  ),
                  onPressed: onLike,
                ),
                const SizedBox(width: 4),
                Text('$likes'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: onComment,
                ),
                const SizedBox(width: 4),
                Text('$comments'),
                const SizedBox(width: 16),
                const Icon(Icons.send),
                const SizedBox(width: 4),
                Text('$shares'),
              ],
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Text(description),
            ),
        ],
      ),
    );
  }
}
