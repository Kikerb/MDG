import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../main.dart'; // Asegúrate de que la ruta es correcta
import '../../widgets/bottom_navigation_bar.dart'; // Tu barra de navegación
import '../market/part_detail_screen.dart';
import '../setings/ConfiguracionUser.dart'; // Pantalla de configuración del usuario
import '../../models/vehicle_model.dart'; // Clase VehicleModel
import 'vehicle/addvehiclescreen.dart'; // Pantalla añadir vehículo
import 'vehicle/vehicle_detail_screen.dart'; // Pantalla de detalles del vehículo
import '../../models/user_model.dart';
// Import del PartRepository y PartModel
import '../../repository/part_repository.dart';
import '../../models/part_model.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _profileImageUrl =
      'https://i.imgur.com/BoN9kdC.png'; // Imagen de perfil por defecto

  // Índice para la barra de navegación (aquí "Garage" es el índice 4)
  int _currentIndex = 4;

  // Posición del tap en la imagen de perfil
  Offset? tapPosition;

  // TabController para las pestañas (Vehículos, Piezas, Favoritos)
  late TabController _tabController;

  // Instancia del PartRepository para gestionar piezas
  final PartRepository _partRepository = PartRepository();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserProfile();

    // Escucha los cambios en la autenticación para actualizar el usuario
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user != _currentUser) {
        setState(() {
          _currentUser = user;
          _loadUserProfile();
        });
      } else if (user == null && _currentUser != null) {
        setState(() {
          _currentUser = null;
          _profileImageUrl = 'https://i.imgur.com/BoN9kdC.png';
        });
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(loginScreenRoute);
        }
      }
    });

    // Inicializa el TabController con 3 pestañas
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      final doc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _profileImageUrl =
              doc.data()?['profileImageUrl'] as String? ??
              'https://i.imgur.com/BoN9kdC.png';
        });
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName =
          '${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$fileName',
      );
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen a Firebase Storage: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      try {
        String? downloadUrl = await _uploadImageToFirebase(imageFile);
        if (downloadUrl != null) {
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'profileImageUrl': downloadUrl,
          });
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagen de perfil actualizada.')),
            );
          }
        }
      } catch (e) {
        print('Error al subir imagen o actualizar perfil: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar la imagen: $e')),
          );
        }
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Usar cámara',
                  style: TextStyle(color: Colors.white),
                ),
                tileColor: Colors.black,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
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
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & MediaQuery.of(context).size,
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          value: 'cambiar_foto',
          child: const Text(
            'Cambiar foto de perfil',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              _showImagePickerOptions();
            });
          },
        ),
        PopupMenuItem(
          value: 'cerrar_sesion',
          child: const Text(
            'Cerrar Sesión',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () async {
            Future.delayed(const Duration(milliseconds: 100), () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(loginScreenRoute);
              }
            });
          },
        ),
      ],
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Mi Garaje', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0033), Color.fromARGB(255, 60, 0, 100)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Inicia sesión para ver tu garaje y perfil.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
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
    }

    final String userId = _currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mi Garaje',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0033), Color.fromARGB(255, 60, 0, 100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // HEADER DE PERFIL
            Row(
              children: [
                // Imagen de perfil con menú al pulsar
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: GestureDetector(
                    onTapDown: (details) {
                      tapPosition = details.globalPosition;
                    },
                    onTap: () {
                      if (tapPosition != null) {
                        _showProfileMenu(context, tapPosition!);
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(_profileImageUrl),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purpleAccent,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Nombre del usuario y contadores
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            _firestore
                                .collection('users')
                                .doc(userId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Cargando...',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text(
                              'Usuario',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          final userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final String userName =
                              userData['name'] ??
                              userData['email'] ??
                              'Usuario';
                          return Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const ConfiguracionUser(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      // Contadores de seguidores, seguidos y vehículos
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .snapshots(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Cargando contadores...',
                              style: TextStyle(color: Colors.white70),
                            );
                          }
                          if (userSnapshot.hasError) {
                            return Text(
                              'Error: ${userSnapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            );
                          }
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const Text(
                              'Seguidores: 0  Seguidos: 0  Vehículos: 0',
                              style: TextStyle(color: Colors.white70),
                            );
                          }
                          final userDoc = userSnapshot.data!;
                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final int followers =
                              (userData['followers'] as List?)?.length ?? 0;
                          final int following =
                              (userData['following'] as List?)?.length ?? 0;
                          return StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('vehicles')
                                    .where('userId', isEqualTo: userId)
                                    .snapshots(),
                            builder: (context, vehicleSnapshot) {
                              if (vehicleSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  'Cargando contadores...',
                                  style: TextStyle(color: Colors.white70),
                                );
                              }
                              if (vehicleSnapshot.hasError) {
                                return Text(
                                  'Error: ${vehicleSnapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                );
                              }
                              final int totalVehicles =
                                  vehicleSnapshot.data?.docs.length ?? 0;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('SEGUIDORES', followers),
                                  _buildStatColumn('SEGUIDOS', following),
                                  _buildStatColumn('VEHÍCULOS', totalVehicles),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Pestañas: Vehículos, Piezas, Favoritos
            Container(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.purpleAccent,
                labelColor: Colors.purpleAccent,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.directions_car, size: 28),
                    text: 'Vehículos',
                  ),
                  Tab(icon: Icon(Icons.build, size: 28), text: 'Piezas'),
                  Tab(icon: Icon(Icons.star, size: 28), text: 'Favoritos'),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña de Vehículos
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.purpleAccent,
                          ),
                        );
                      }

                      if (userSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar usuario: ${userSnapshot.error}',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'Usuario no encontrado.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final int garageSlots =
                          userData['garageSlots'] ??
                          3; // Valor por defecto si no está en la BD

                      return StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('vehicles')
                                .where('userId', isEqualTo: userId)
                                .orderBy('addedAt', descending: true)
                                .snapshots(),
                        builder: (context, vehicleSnapshot) {
                          if (vehicleSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.purpleAccent,
                              ),
                            );
                          }

                          if (vehicleSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error al cargar vehículos: ${vehicleSnapshot.error}',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            );
                          }

                          final List<VehicleModel> vehicles =
                              vehicleSnapshot.data!.docs
                                  .map((doc) => VehicleModel.fromFirestore(doc))
                                  .toList();

                          return _buildGarageGrid(
                            context,
                            vehicles,
                            garageSlots,
                          );
                        },
                      );
                    },
                  ),
                  // Pestaña de Piezas: se muestran las piezas publicadas por el usuario
                  FutureBuilder<List<PartModel>>(
                    future: _partRepository.fetchPartsByUser(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.purpleAccent,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar piezas: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      final List<PartModel> parts = snapshot.data ?? [];
                      if (parts.isEmpty) {
                        return const Center(
                          child: Text(
                            'No tienes piezas subidas.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: parts.length,
                        itemBuilder: (context, index) {
                          return _buildPartCard(context, parts[index]);
                        },
                      );
                    },
                  ),
                  // Pestaña de Favoritos (marcador de posición)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Aquí se mostrarán tus elementos favoritos.',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
  }

  // Widget para la columna de estadísticas (seguidores, seguidos, vehículos)
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // Widget para construir la cuadrícula del garaje (vehículos y plazas vacías)
  Widget _buildGarageGrid(
    BuildContext context,
    List<VehicleModel> vehicles,
    int maxSlots,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.7,
      ),
      itemCount: maxSlots,
      itemBuilder: (context, index) {
        VehicleModel? vehicleInSlot;
        if (index < vehicles.length) {
          vehicleInSlot = vehicles[index];
        }

        if (vehicleInSlot != null) {
          return _buildVehicleCard(context, vehicleInSlot);
        } else {
          return _buildAddVehicleButton(context, index);
        }
      },
    );
  }

  // Widget para la tarjeta de un vehículo
  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    String displayPrice = 'N/A';
    if (vehicle.currentStatus == 'En Venta' && vehicle.price != null) {
      displayPrice = '${vehicle.price!.toStringAsFixed(0)} €';
    } else if (vehicle.currentStatus == 'Escucha Ofertas') {
      displayPrice = 'Escucha Ofertas';
    } else {
      displayPrice = vehicle.currentStatus;
    }

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
                child: Image.network(
                  vehicle.mainImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.purpleAccent,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[700],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayPrice,
                    style: TextStyle(
                      color:
                          vehicle.currentStatus == 'Vendido'
                              ? Colors.redAccent
                              : Colors.lightGreenAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estado: ${vehicle.currentStatus}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para el botón de añadir vehículo en una plaza vacía
  Widget _buildAddVehicleButton(BuildContext context, int slotIndex) {
    return Card(
      color: const Color(0xFF1A0033),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Colors.purpleAccent, width: 2),
      ),
      elevation: 5,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 60,
              color: Colors.white70,
            ),
            const SizedBox(height: 10),
            const Text(
              'Añadir Vehículo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Plaza libre #${slotIndex + 1}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir la tarjeta de una pieza usando PartModel
  Widget _buildPartCard(BuildContext context, PartModel part) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PartDetailScreen(part: part)),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
                child: Image.network(
                  part.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.purpleAccent,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[700],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                part.partName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
