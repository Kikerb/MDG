import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String searchText = '';
  int _currentIndex = 1; // Índice de la pestaña actual (Buscar)
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
              hintText: 'Buscar usuarios por email...',
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

          final allUsers = snapshot.data!.docs;

          if (searchText.isEmpty) {
            final testerUsers = allUsers.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              final email = data != null && data.containsKey('email')
                  ? (data['email'] ?? '').toString().toLowerCase()
                  : '';
              return email == 'tester@example.com'; // Cambia aquí al email deseado
            }).toList();

            if (testerUsers.isEmpty) {
              return const Center(
                child: Text(
                  'Usuario tester no encontrado.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final testerUser = testerUsers.first;
            return ListView(children: [_buildUserTile(testerUser)]);
          }

          final filteredUsers = allUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final email = data != null && data.containsKey('email')
                ? (data['email'] ?? '').toString().toLowerCase()
                : '';
            return email.contains(searchText.toLowerCase());
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
              return _buildUserTile(user);
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A0033),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return; // Si tocan la misma pestaña, no hacer nada

          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed(garageScreenRoute);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Garage',
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>? ?? {};
    final username = data['username'] ?? 'Sin nombre';
    final email = data['email'] ?? '';
    final profileImage =
        data['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profileImage),
        radius: 24,
      ),
      title: Text(username, style: const TextStyle(color: Colors.white)),
      subtitle: Text(email, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver perfil de $username')),
        );
      },
    );
  }
}
