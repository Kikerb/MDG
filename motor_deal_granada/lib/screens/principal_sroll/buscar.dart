import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Buscar usuarios...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                searchText = value.trim();
              });
            },
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            );
          }

          final filteredUsers = snapshot.data!.docs.where((doc) {
            final username = (doc['username'] ?? '').toString().toLowerCase();
            return username.contains(searchText.toLowerCase());
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron usuarios.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final username = user['username'] ?? 'Sin nombre';
              final email = user['email'] ?? '';
              final profileImage = user['profileImageUrl'] ??
                  'https://i.imgur.com/BoN9kdC.png';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(profileImage),
                  radius: 24,
                ),
                title: Text(
                  username,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  // Acción al tocar usuario (por ejemplo: ir al perfil)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ver perfil de $username')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
