import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import '../../main.dart'; // Importa main.dart para las rutas nombradas
import '../../widgets/bottom_navigation_bar.dart'; // Importa tu barra de navegación

import '../setings/ConfiguracionUser.dart'; // Ajusta la ruta si es necesario
import '../../models/vehicle_model.dart'; // Ajusta la ruta a tu VehicleModel
import 'vehicle/addvehiclescreen.dart'; // La pantalla para añadir vehículos
import 'vehicle/vehicle_detail_screen.dart'; // La pantalla de detalles del vehículo

// Eliminamos PrivateGarageScreen y fusionamos su contenido aquí.

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

  // Define el número máximo de plazas de garaje
  final int _maxGarageSlots = 3;

  // Usamos _currentIndex para el CustomBottomNavigationBar.
  // Ajusta el índice inicial si tu "Garaje" no es el tercero (índice 2).
  int _currentIndex = 4; // Índice para la barra de navegación: 'Garage'

  // Variable para la posición del tap para el menú de perfil
  Offset? tapPosition;

  // TabController para las nuevas pestañas
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserProfile();

    // Escuchar cambios de autenticación
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user != _currentUser) {
        setState(() {
          _currentUser = user;
          _loadUserProfile(); // Cargar el perfil del nuevo usuario
        });
      } else if (user == null && _currentUser != null) {
        // El usuario ha cerrado sesión
        setState(() {
          _currentUser = null;
          _profileImageUrl =
              'https://i.imgur.com/BoN9kdC.png'; // Restablecer a la imagen por defecto
        });
        if (mounted) {
          // Redirige a la pantalla de login si el usuario cierra sesión
          Navigator.of(context).pushReplacementNamed(loginScreenRoute);
        }
      }
    });

    // Inicializa el TabController con 3 pestañas
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Es importante liberar el TabController
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
          color: Colors.black, // Fondo negro para el modal
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
        position & const Size(40, 40), // Tamaño del área del botón
        Offset.zero & MediaQuery.of(context).size, // Tamaño de toda la pantalla
      ),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          value: 'cambiar_foto',
          child: const Text(
            'Cambiar foto de perfil',
            style: TextStyle(color: Colors.white), // Color del texto
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
            style: TextStyle(color: Colors.white), // Color del texto
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
      color: Colors.black, // Color de fondo del menú
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
            // La navegación real debe ocurrir aquí o en CustomBottomNavigationBar
            // Ejemplo: if (index == 0) Navigator.pushNamed(context, homeRoute);
          },
        ),
      );
    }

    final String userId = _currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black, // Fondo principal oscuro
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Transparente para que se vea el gradiente
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
            // HEADER DE PERFIL (como en la imagen)
            Row(
              children: [
                // Imagen de perfil
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
                      radius:
                          50, // Ajusta el radio para que coincida con la imagen
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
                // Nombre de usuario y contadores
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
                                  fontSize:
                                      22, // Tamaño más grande para el nombre
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Botón de edición de perfil
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
                              'Seguidores: 0 Seguidos: 0 Vehículos: 0',
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
            // Barra de pestañas (Vehículos, Piezas, Favoritos)
            Container(
              color: Colors.black, // Fondo negro para la barra de pestañas
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.purpleAccent, // Color del indicador
                labelColor:
                    Colors.purpleAccent, // Color de la pestaña seleccionada
                unselectedLabelColor:
                    Colors.white70, // Color de las pestañas no seleccionadas
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
            // Contenido de las pestañas
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.6, // Ajusta la altura según sea necesario
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña de Vehículos
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
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
                        return Center(
                          child: Text(
                            'Error al cargar vehículos: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final List<VehicleModel> vehicles =
                          snapshot.data!.docs
                              .map((doc) => VehicleModel.fromFirestore(doc))
                              .toList();

                      // Construir la cuadrícula de garaje con los vehículos y las plazas vacías
                      return _buildGarageGrid(context, vehicles);
                    },
                  ),
                  // Pestaña de Piezas (Marcador de posición)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.construction,
                          size: 80,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Aquí se mostrarán tus piezas.',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  // Pestaña de Favoritos (Marcador de posición)
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
      // Integración del CustomBottomNavigationBar
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

  // Widget para construir la columna de estadísticas (seguidores, seguidos, vehículos)
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

  // Widget para construir la cuadrícula del garaje (vehículos + plazas vacías)
  Widget _buildGarageGrid(BuildContext context, List<VehicleModel> vehicles) {
    return GridView.builder(
      shrinkWrap:
          true, // Importante para que el GridView no ocupe todo el espacio y permita el SingleChildScrollView
      physics:
          const NeverScrollableScrollPhysics(), // Deshabilita el scroll interno del GridView
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas por fila
        crossAxisSpacing: 10.0, // Espacio horizontal entre tarjetas
        mainAxisSpacing: 10.0, // Espacio vertical entre tarjetas
        childAspectRatio:
            0.7, // Ajusta la relación de aspecto de las tarjetas para que sean más pequeñas
      ),
      itemCount:
          vehicles.length > _maxGarageSlots
              ? vehicles.length
              : _maxGarageSlots, // Muestra siempre el número máximo de plazas o más si hay más vehículos
      itemBuilder: (context, index) {
        // Intentar encontrar un vehículo para esta "plaza"
        VehicleModel? vehicleInSlot;
        if (index < vehicles.length) {
          vehicleInSlot = vehicles[index];
        }

        if (vehicleInSlot != null) {
          // Si hay un vehículo en esta plaza, muestra su información
          return _buildVehicleCard(context, vehicleInSlot);
        } else {
          // Si la plaza está vacía y estamos dentro del límite de _maxGarageSlots, muestra un botón para añadir un vehículo
          if (index < _maxGarageSlots) {
            return _buildAddVehicleButton(context, index);
          } else {
            // No renderizar nada si hay más vehículos que _maxGarageSlots y no hay más plazas para añadir
            return Container();
          }
        }
      },
    );
  }

  // Widget para la tarjeta de un vehículo en el garaje
  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    // Preparar el texto del precio y estado para la tarjeta
    String displayPrice = 'N/A';
    if (vehicle.currentStatus == 'En Venta' && vehicle.price != null) {
      displayPrice =
          '${vehicle.price!.toStringAsFixed(0)} €'; // Asume euros, ajusta si es necesario
    } else if (vehicle.currentStatus == 'Escucha Ofertas') {
      displayPrice = 'Escucha Ofertas';
    } else {
      displayPrice =
          vehicle.currentStatus; // Mostrar el estado si no es "En Venta"
    }

    return Card(
      color: Colors.grey[900], // Fondo oscuro para la tarjeta
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          // Al tocar el vehículo, navega a la pantalla de detalles
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
        side: const BorderSide(
          color: Colors.purpleAccent,
          width: 2,
        ), // Borde distintivo
      ),
      elevation: 5,
      child: InkWell(
        // Para el efecto ripple al tocar
        onTap: () async {
          // Navegar a la pantalla de añadir vehículo y esperar un resultado
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
}
