import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../widgets/Posts.dart';
import '../../widgets/bottom_navigation_bar.dart';

import '../../screens/principal_sroll/ConfiguracionUser.dart';
import '../../screens/principal_sroll/subir_coche.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String selectedFilter = 'Todos';
  int _currentIndex = 2;
  Offset? tapPosition;

  Future<String?> _getProfileImageUrl(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Usar cámara', style: TextStyle(color: Colors.white)),
                tileColor: Colors.black,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Seleccionar de galería', style: TextStyle(color: Colors.white)),
                tileColor: Colors.black,
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
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada.')),
          );
        } catch (e) {
          print('Error al subir la imagen: $e');
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
        const PopupMenuItem(
          value: 'cambiar_foto',
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.black),
              SizedBox(width: 8),
              Text('Cambiar Foto'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.black),
              SizedBox(width: 8),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );

    if (selected == 'cambiar_foto') {
      _mostrarSeleccionImagen(context);
    } else if (selected == 'logout') {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(loginScreenRoute);
      }
    }
  }

  Future<void> _handleLike(String postId, Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance.collection('Posts').doc(postId);
    try {
      final currentLikes = (data['likes'] ?? 0) as int;
      await docRef.update({'likes': currentLikes + 1});
    } catch (e) {
      print('Error actualizando likes: $e');
    }
  }

  void _handleComment(String postId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abrir comentarios para post $postId')),
    );
  }

  Widget _buildFilterButton(String text) {
    final bool isSelected = selectedFilter == text;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purpleAccent : Colors.grey[700],
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: Text(text),
    );
  }

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

        return FutureBuilder<String?>(
          future: _getProfileImageUrl(userId),
          builder: (context, snapshotUrl) {
            String imageUrl = 'https://i.imgur.com/BoN9kdC.png';
            if (snapshotUrl.connectionState == ConnectionState.done &&
                snapshotUrl.data?.isNotEmpty == true) {
              imageUrl = snapshotUrl.data!;
            }

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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.directions_car, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubirCocheScreen(),
                        ),
                      );
                    },
                  ),
                ],
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
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            'Seguidos: 0   Seguidores: 0',
                            style: TextStyle(color: Colors.white),
                          );
                        }
                        final userDoc = snapshot.data!;
                        final seguidores = userDoc['followersCount'] ?? 0;
                        final seguidos = userDoc['followingCount'] ?? 0;
                        return Text(
                          'Seguidos: $seguidos   Seguidores: $seguidores',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterButton('Todos'),
                        const SizedBox(width: 8),
                        _buildFilterButton('En venta'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Vendido'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('userId', isEqualTo: userId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                        }
                        if (snapshot.hasError) {
                          print('Error al cargar posts del usuario: ${snapshot.error}');
                          return Center(
                            child: Text(
                              'Error al cargar tus publicaciones: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
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

                        final filteredDocs = snapshot.data!.docs.where((doc) {
                          if (selectedFilter == 'Todos') return true;
                          final data = doc.data() as Map<String, dynamic>;
                          if (selectedFilter == 'En venta') {
                            return (data['currentStatus'] == 'En Venta' || data['currentStatus'] == 'Escucha Ofertas');
                          }
                          if (selectedFilter == 'Vendido') {
                            return data['currentStatus'] == 'Vendido';
                          }
                          return true;
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay publicaciones "${selectedFilter.toLowerCase()}" para mostrar.',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return PostCard(
                              postId: doc.id,
                              username: data['username'] ?? 'Usuario Desconocido',
                              imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
                              description: data['description'] ?? '',
                              likes: data['likesCount'] ?? 0,
                              comments: data['commentsCount'] ?? 0,
                              shares: data['sharesCount'] ?? 0,
                              onLike: () => _handleLike(doc.id, data),
                              onComment: () => _handleComment(doc.id),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: _currentIndex,
                onItemSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}