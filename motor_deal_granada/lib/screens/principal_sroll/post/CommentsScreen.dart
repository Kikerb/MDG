import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({required this.postId, Key? key}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _addComment() async {
  final text = _commentController.text.trim();
  if (text.isEmpty) return;

  await FirebaseFirestore.instance
      .collection('Posts')
      .doc(widget.postId)
      .collection('comments')
      .add({
    'userId': currentUser?.uid,
    'username': currentUser?.displayName ?? 'Anónimo',
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  });

  _commentController.clear();
  
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop(true);
  }
}


  @override
  Widget build(BuildContext context) {
    final commentsRef = FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Error al cargar comentarios', style: TextStyle(color: Colors.white));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(child: Text('No hay comentarios aún.', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  reverse: true, // Para mostrar el comentario más reciente arriba
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data()! as Map<String, dynamic>;
                    final username = commentData['username'] ?? 'Anonimo';
                    final text = commentData['text'] ?? '';
                    final timestamp = commentData['timestamp'] as Timestamp?;
                    final timeString = timestamp != null
                        ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
                        : '';

                    return ListTile(
                      title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(text, style: const TextStyle(color: Colors.white70)),
                      trailing: Text(timeString, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purpleAccent),
                  onPressed: _addComment,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
