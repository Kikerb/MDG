import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Posts.dart';

class garage extends StatefulWidget {
  final String userId;
  const garage({super.key, required this.userId});

  @override
  State<garage> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<garage> {
  String selectedFilter = 'Todos'; // Puede ser: Todos, Coche, Piezas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text('GARAGE', style: TextStyle(fontSize: 28, color: Colors.purple, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage('https://i.imgur.com/BoN9kdC.png'), // Imagen temporal
            ),
            const SizedBox(height: 8),
            Text('juliokomar@gmail.com', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),

            // Seguidores / Seguidos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {},
                  child: Text('SEGUIDORES', style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () {},
                  child: Text('SEGUIDOS', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filtro ComboBox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: DropdownButton<String>(
                dropdownColor: Colors.black,
                value: selectedFilter,
                isExpanded: true,
                items: ['Todos', 'Coche', 'Piezas']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedFilter = value;
                    });
                  }
                },
              ),
            ),

            const Divider(color: Colors.white24, thickness: 1, height: 30),

            // Posts del usuario filtrados
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: widget.userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedFilter == 'Todos') return true;
                  return data['tipo'] == selectedFilter; // asume campo 'tipo': 'Coche' / 'Piezas'
                }).toList();

                return Column(
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return PostCard(
                      username: data['username'] ?? '',
                      imageUrl: data['imageUrl'] ?? '',
                      likes: data['likes'] ?? 0,
                      comments: data['comments'] ?? 0,
                      shares: data['shares'] ?? 0,
                      description: data['description'] ?? '',
                    );
                  }).toList(),
                );
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: ''),
        ],
      ),
    );
  }
}
