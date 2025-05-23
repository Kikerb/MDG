import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Posts.dart';
import 'ConfiguracionUser.dart';
import '../../main.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String selectedFilter = 'Todos';
  int _currentIndex = 2;

  Future<String?> _getProfileImageUrl(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        return doc.data()?['profileImageUrl'] as String?;
      }
    } catch (e) {
      print('Error obteniendo foto de perfil: $e');
    }
    return null;
  }

  Future<void> _mostrarSeleccionImagen(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Usar cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final file = File(picked.path);
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        try {
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImageUrl': url});
          setState(() {}); // Para refrescar la imagen en pantalla
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir la imagen: $e')),
          );
        }
      }
    }
  }

  void _showProfileMenu(BuildContext context, Offset tapPosition) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'cambiar_foto',
          child: Row(
            children: const [
              Icon(Icons.camera_alt, color: Colors.black),
              SizedBox(width: 8),
              Text('Cambiar Foto'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );

    if (selected == 'perfil') {
      // Acción para ir a perfil
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ir a Perfil')));
    } else if (selected == 'cambiar_foto') {
      _mostrarSeleccionImagen(context);
    } else if (selected == 'logout') {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
          );
        }

        if (snapshot.hasError) {
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
            Navigator.of(
              context,
            ).pushReplacementNamed('/login'); // Cambia por tu ruta de login
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

        return FutureBuilder<String?>(
          future: _getProfileImageUrl(userId),
          builder: (context, snapshotUrl) {
            String imageUrl = 'https://i.imgur.com/BoN9kdC.png';
            if (snapshotUrl.connectionState == ConnectionState.done &&
                snapshotUrl.data?.isNotEmpty == true) {
              imageUrl = snapshotUrl.data!;
            }

            Offset? tapPosition;

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
                leading: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfiguracionUser(),
                      ),
                    );
                  },
                ),
              ),
              drawer: Drawer(
                backgroundColor: Colors.black,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.purpleAccent,
                      ),
                      child: Text(
                        userEmail,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: const Text(
                        'Perfil',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ir a Perfil')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacementNamed(
                          '/login',
                        ); // Cambia por tu ruta de login
                      },
                    ),
                  ],
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'GARAGE',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GestureDetector(
                      onTapDown: (details) {
                        tapPosition = details.globalPosition;
                      },
                      onTap: () {
                        if (tapPosition != null) {
                          _showProfileMenu(context, tapPosition!);
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            'Seguidos: 0  Seguidores: 0',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                            {};

                        final seguidores =
                            (data['followers'] as List<dynamic>?)?.length ?? 0;
                        final seguidos =
                            (data['following'] as List<dynamic>?)?.length ?? 0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Seguidos: $seguidos',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              'Seguidores: $seguidores',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      },
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
                          DropdownMenuItem(
                            value: 'Todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'En venta',
                            child: Text('En venta'),
                          ),
                          DropdownMenuItem(
                            value: 'Vendido',
                            child: Text('Vendido'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('Posts')
                              .where('uid', isEqualTo: userId)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          );
                        }
                        final docs =
                            snapshot.data!.docs.where((doc) {
                              if (selectedFilter == 'Todos') {
                                return true;
                              } else if (selectedFilter == 'En venta') {
                                return doc['vendido'] == false;
                              } else if (selectedFilter == 'Vendido') {
                                return doc['vendido'] == true;
                              }
                              return true;
                            }).toList();

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return PostCard(
                              username: doc['username'] ?? 'Usuario',
                              imageUrl: doc['imageUrl'] ?? '',
                              likes: doc['likes'] ?? 0,
                              comments: doc['comments'] ?? 0,
                              shares: doc['shares'] ?? 0,
                              description: doc['description'] ?? '',
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                backgroundColor: Colors.black,
                currentIndex: _currentIndex,
                selectedItemColor: Colors.purpleAccent,
                unselectedItemColor: Colors.white,
                onTap: (index) {
                  if (index == _currentIndex) return; // Evita reload innecesario
                  setState(() {
                    _currentIndex = index;
                  });
                  if (index == 0) {
                    Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
                  } else if (index == 1) {
                    Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
                  } else if (index == 2) {
                    Navigator.of(context).pushReplacementNamed(garageScreenRoute);
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Buscar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.garage),
                    label: 'Garage',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
