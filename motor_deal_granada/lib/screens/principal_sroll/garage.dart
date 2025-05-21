import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motor_deal_granada/main.dart'; // <--- Importa main.dart para las rutas
import 'Posts.dart'; // Asumo que este archivo contiene tu widget PostCard

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String selectedFilter = 'Todos';

  // Mantener el índice actual de la barra de navegación para que el ícono esté seleccionado
  // Si esta pantalla es la del garaje, su índice debería ser 2 (0=Inicio, 1=Mis Posts, 2=Garage)
  int _currentIndex = 2; // Establecemos el índice inicial en 2 para Garage

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black, // Fondo negro para el loading
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
          // Si no hay usuario logueado, redirigir a la pantalla de autenticación/login
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
          backgroundColor: Colors.black, // Fondo negro

          appBar: AppBar(
            backgroundColor: Colors.black, // Fondo negro para la AppBar
            elevation: 0, // Sin sombra
            title: const Text(
              'Mi Garaje', // Título para la pantalla de Garaje
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            // Puedes añadir iconos aquí si la pantalla de Garaje los necesita,
            // por ejemplo, para añadir un nuevo coche o pieza.
          ),

          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('GARAGE', // Título principal de la sección
                    style: TextStyle(
                        fontSize: 28,
                        color: Colors.purpleAccent, // Color más vibrante
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                      'https://i.imgur.com/BoN9kdC.png'), // Imagen temporal de perfil
                ),
                const SizedBox(height: 8),
                Text(userEmail, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7), // Fondo morado
                        foregroundColor: Colors.white, // Texto blanco
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Lógica para ver seguidores
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ver Seguidores')),
                        );
                      },
                      child: const Text('SEGUIDORES'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7), // Fondo morado
                        foregroundColor: Colors.white, // Texto blanco
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Lógica para ver seguidos
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
                    dropdownColor: const Color(0xFF1A0033), // Fondo del dropdown oscuro
                    value: selectedFilter,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white), // Color del texto seleccionado
                    underline: Container(
                      height: 2,
                      color: Colors.purpleAccent, // Línea debajo del dropdown
                    ),
                    iconEnabledColor: Colors.white, // Color del icono de la flecha
                    items: const [ // Usamos const para los DropdownMenuItem si no cambian
                      DropdownMenuItem(value: 'Todos', child: Text('Todos', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Coche', child: Text('Coches', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'Piezas', child: Text('Piezas', style: TextStyle(color: Colors.white))),
                    ]
                        .map((e) => e) // Esto es para mantener la lista tal cual
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
                      .where('tipo', isEqualTo: selectedFilter == 'Todos' ? null : selectedFilter) // Filtrar por tipo
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

          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF1A0033), // Fondo de la barra púrpura oscuro
            selectedItemColor: Colors.purpleAccent, // Color del icono seleccionado
            unselectedItemColor: Colors.white, // Color del icono no seleccionado
            currentIndex: _currentIndex, // Usa la variable de estado
            onTap: (index) {
              setState(() {
                _currentIndex = index; // Actualiza el índice seleccionado
              });
              // Lógica para navegar entre secciones
              switch (index) {
                case 0:
                  // Navegar a la pantalla de Inicio (ScrollScreen)
                  Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
                  break;
                case 1:
                  // Mis Posts (si tienes una pantalla específica, si no, puedes manejarlo aquí)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abriendo Mis Posts (ruta no implementada)')),
                  );
                  // Si 'Mis Posts' es otra pantalla, crea una ruta similar a garageScreenRoute.
                  break;
                case 2:
                  // Ya estamos en la pantalla de Garaje, no hacer nada o recargar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ya estás en Garaje')),
                  );
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Inicio', // Texto en español
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_open), // O un icono que represente "mis posts"
                label: 'Mis Posts', // Texto en español
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warehouse), // O un icono que represente un garaje
                label: 'Garaje', // Texto en español
              ),
            ],
          ),
        );
      },
    );
  }
}