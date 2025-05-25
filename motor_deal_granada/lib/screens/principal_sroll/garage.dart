import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motor_deal_granada/main.dart'; // Importa main.dart para las rutas
import '../../widgets/Posts.dart'; // widget PostCard
import '../../widgets/bottom_navigation_bar.dart'; // widget barra de navegacion de abajo

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String selectedFilter = 'Todos';

  int _currentIndex = 1; // Índice para Garaje (1)

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          );
        }

        if (snapshot.hasError) {
          print('Error al cargar usuario en GarageScreen: ${snapshot.error}');
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Error al cargar la información del usuario.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(loginScreenRoute);
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No hay usuario autenticado. Redirigiendo...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final user = snapshot.data!;
        final userEmail = user.email ?? 'Usuario desconocido';
        final userId = user.uid;

        return Scaffold(
          backgroundColor: Colors.black,

          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Mi Garaje',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),

          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('GARAGE',
                    style: TextStyle(
                        fontSize: 28,
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                      'https://i.imgur.com/BoN9kdC.png'),
                ),
                const SizedBox(height: 8),
                Text(userEmail, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ver Seguidores')),
                        );
                      },
                      child: const Text('SEGUIDORES'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ver Seguidos')),
                        );
                      },
                      child: const Text('SEGUIDOS'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1A0033),
                    value: selectedFilter,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(
                      height: 2,
                      color: Colors.purpleAccent,
                    ),
                    iconEnabledColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Coche', child: Text('Coches', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Piezas', child: Text('Piezas', style: TextStyle(color: Colors.white))),
                    ]
                        .map((e) => e)
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: userId)
                      .where('tipo', isEqualTo: selectedFilter == 'Todos' ? null : selectedFilter)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }
                    if (snapshot.hasError) {
                      print('Error al cargar posts del usuario: ${snapshot.error}');
                      return const Center(
                        child: Text(
                          'Error al cargar tus publicaciones.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no tienes publicaciones en tu garaje.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final posts = snapshot.data!.docs;

                    return Column(
                      children: posts.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return PostCard(
                          username: data['username'] ?? 'Usuario Desconocido',
                          imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
                          likes: data['likes'] ?? 0,
                          comments: data['comments'] ?? 0,
                          shares: data['shares'] ?? 0,
                          description: data['description'] ?? '',
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          bottomNavigationBar: CustomBottomNavigationBar( // <--- ¡USANDO EL WIDGET PERSONALIZADO!
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index; // Actualiza el índice seleccionado
              });
              // La navegación se maneja dentro de CustomBottomNavigationBar
            },
          ),
        );
      },
    );
  }
}