import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart'; // Asumo que main.dart contiene loginScreenRoute
import '../../models/user_model.dart'; // Importa tu modelo de usuario
import '../../models/vehicle_model.dart'; // Importa tu modelo de vehículo
import '../../repository/user_repository.dart'; // Importa tu repositorio de usuario
import '../../widgets/bottom_navigation_bar.dart'; // Asegúrate de que esta es la ruta correcta para tu barra de navegación personalizada

import '../../screens/principal_sroll/ConfiguracionUser.dart';
import '../../screens/principal_sroll/subir_coche.dart';
import 'Posts.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  String selectedFilter = 'Todos';
  int _currentIndex = 2; // Mantén este valor en 2 para la pestaña de Garaje
  Offset? tapPosition;

  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository();
  }

  Future<void> _mostrarSeleccionImagen(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          color: Colors.black,
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text(
                    'Usar cámara',
                    style: TextStyle(color: Colors.white),
                  ),
                  tileColor: Colors.black,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text(
                    'Seleccionar de galería',
                    style: TextStyle(color: Colors.white),
                  ),
                  tileColor: Colors.black,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
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
          await _userRepository.updateProfileImageUrl(user.uid, url);

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

  Future<void> _handleLike(String vehicleId) async {
    print('Me gusta manejado para el vehículo $vehicleId');
  }

  void _handleComment(String vehicleId) {
    print('Comentario manejado para el vehículo $vehicleId');
  }

  Widget _buildFilterIcon(String filterName, IconData icon) {
    final bool isSelected = selectedFilter == filterName;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.purpleAccent : Colors.white,
        size: 28,
      ),
      onPressed: () {
        setState(() {
          selectedFilter = filterName;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
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

        final user = authSnapshot.data!;
        final userId = user.uid;

        return StreamBuilder<UserModel>(
          stream: _userRepository.getUserStream(userId),
          builder: (context, userModelSnapshot) {
            if (userModelSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child:
                      CircularProgressIndicator(color: Colors.purpleAccent),
                ),
              );
            }
            if (userModelSnapshot.hasError) {
              print(
                  'Error al cargar userModel en GarageScreen: ${userModelSnapshot.error}');
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'Error al cargar perfil: ${userModelSnapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            if (!userModelSnapshot.hasData || userModelSnapshot.data == null) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'Perfil de usuario no encontrado.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            final userModel = userModelSnapshot.data!;

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                title: const Text(
                  'Mi Garaje', // Título de la AppBar
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
                  // Quitar el botón de 'directions_car' de la AppBar si la funcionalidad
                  // de añadir coche se gestiona desde los "espacios vacíos" en el GridView
                  // IconButton(
                  //   icon: const Icon(Icons.directions_car, color: Colors.white),
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const SubirCocheScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Sección de Información de Perfil al estilo de la imagen
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              radius: 45, // Tamaño de avatar ajustado
                              backgroundColor: Colors.grey[800],
                              backgroundImage: userModel.profileImageUrl != null &&
                                      userModel.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(userModel.profileImageUrl!)
                                  : const NetworkImage(
                                      'https://i.imgur.com/BoN9kdC.png'),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      userModel.username,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navegar a la pantalla de edición de perfil
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ConfiguracionUser(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800], // Color de fondo del botón
                                        foregroundColor: Colors.white, // Color del texto del botón
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Editar perfil'),
                                    ),
                                    const SizedBox(width: 10),
                                    // Eliminado el botón "Ver archivo"
                                    // IconButton(
                                    //   icon: Icon(Icons.more_vert, color: Colors.white),
                                    //   onPressed: () {
                                    //     // Acción para el botón de archivo/más opciones
                                    //   },
                                    // ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatColumn(
                                        'Vehículos', userModel.garageSlotsUsed),
                                    _buildStatColumn(
                                        'Seguidores', userModel.followersCount),
                                    _buildStatColumn(
                                        'Seguidos', userModel.followingCount),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Breve descripción del perfil
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userModel.bio ?? 'Sin descripción.', // Usa el campo 'bio' o un texto por defecto
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            // Puedes añadir más información aquí si tu UserModel la tiene,
                            // por ejemplo, nombre real, etc.
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Divider(color: Colors.white, thickness: 0.2),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFilterIcon('Todos', Icons.grid_on),
                          _buildFilterIcon('En venta', Icons.sell),
                          _buildFilterIcon('Vendido', Icons.check_circle_outline),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white, thickness: 0.2),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vehicles')
                          .where('userId', isEqualTo: userId)
                          .orderBy('addedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          print(
                              'Error al cargar vehículos del usuario: ${snapshot.error}');
                          return Center(
                            child: Text(
                              'Error al cargar tus vehículos: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        List<VehicleModel> filteredVehicles = [];
                        if (snapshot.hasData) {
                          filteredVehicles = snapshot.data!.docs
                              .map((doc) => VehicleModel.fromFirestore(doc))
                              .where((vehicle) {
                                if (selectedFilter == 'Todos') return true;
                                if (selectedFilter == 'En venta') {
                                  return vehicle.currentStatus == 'En Venta' ||
                                      vehicle.currentStatus == 'Escucha Ofertas';
                                }
                                if (selectedFilter == 'Vendido') {
                                  return vehicle.currentStatus == 'Vendido';
                                }
                                return true;
                              })
                              .toList();
                        }

                        if (filteredVehicles.isEmpty && selectedFilter != 'Todos') {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'No hay vehículos "${selectedFilter.toLowerCase()}" para mostrar.',
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final int totalGarageSlots = userModel.garageSlots;
                        final int vehiclesCount = filteredVehicles.length;
                        final int displayCount = totalGarageSlots; // Mostrar siempre el total de slots

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: displayCount,
                          itemBuilder: (context, index) {
                            if (index < vehiclesCount) {
                              final vehicle = filteredVehicles[index];
                              return PostCard(
                                postId: vehicle.id,
                                username: userModel.username,
                                imageUrl: vehicle.mainImageUrl,
                                likes: 0,
                                comments: 0,
                                shares: 0,
                                description: vehicle.description,
                                isLiked: false,
                                onLike: () => _handleLike(vehicle.id),
                                onComment: () => _handleComment(vehicle.id),
                                onShare: () { /* Lógica de compartir, si aplica */ },
                                showActions: false,
                                showPrice: true,
                                price: '${vehicle.price?.toStringAsFixed(0) ?? 'N/A'} ${vehicle.currency ?? ''}',
                                status: vehicle.currentStatus,
                              );
                            } else {
                              // Mostrar un espacio vacío si hay slots disponibles
                              if (index < totalGarageSlots) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SubirCocheScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    color: Colors.grey[900],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.purpleAccent,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Añadir Coche',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                        const Text(
                                          '(Vacío)',
                                          style: TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // No debería llegar aquí si displayCount es totalGarageSlots
                                // y totalGarageSlots es >= vehiclesCount.
                                return Container(); // O un contenedor vacío para no mostrar nada
                              }
                            }
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
                  // Asegúrate de que tu CustomBottomNavigationBar maneje la navegación
                  // a las otras pantallas (e.g., Noticias_screen para index 0, etc.)
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helper para construir las columnas de estadísticas
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}