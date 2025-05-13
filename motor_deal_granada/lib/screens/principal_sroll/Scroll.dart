import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Posts.dart';

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
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>;

              return PostCard(
                username: data['username'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                likes: data['likes'] ?? 0,
                comments: data['comments'] ?? 0,
                shares: data['shares'] ?? 0,
                description: data['description'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}
