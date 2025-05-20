import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String username, imageUrl, description;
  final int likes, comments, shares;

  const PostCard({super.key, 
    required this.username,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(title: Text(username), leading: Icon(Icons.account_circle)),
          Image.network(imageUrl, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.favorite), SizedBox(width: 4), Text('$likes'),
                SizedBox(width: 16),
                Icon(Icons.comment), SizedBox(width: 4), Text('$comments'),
                SizedBox(width: 16),
                Icon(Icons.send), SizedBox(width: 4), Text('$shares'),
              ],
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(description),
            ),
        ],
      ),
    );
  }
}
