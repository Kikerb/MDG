import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:motor_deal_granada/screens/principal_sroll/Posts.dart'; // Asegúrate de que esta ruta sea correcta para tu PostCard
import 'package:motor_deal_granada/widgets/bottom_navigation_bar.dart'; // Importa tu barra de navegación
import 'package:motor_deal_granada/main.dart'; // Importa main.dart para las rutas nombradas (asumiendo que tienes rutas nombradas como loginRoute)

// Asegúrate de importar tus pantallas de configuración y subir coche
import 'package:motor_deal_granada/screens/principal_sroll/ConfiguracionUser.dart'; // Ajusta la ruta si es necesario
import 'package:motor_deal_granada/screens/principal_sroll/garage.dart'; // Ajusta la ruta si es necesario


class PrivateGarageScreen extends StatefulWidget {
  const PrivateGarageScreen({super.key});

  @override
  State<PrivateGarageScreen> createState() => _PrivateGarageScreenState();
}

class _PrivateGarageScreenState extends State<PrivateGarageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _profileImageUrl = 'https://i.imgur.com/BoN9kdC.png'; // Imagen de perfil por defecto
  String selectedFilter = 'Todos'; // Filtro predeterminado

  // Usamos _currentIndex para el CustomBottomNavigationBar.
  // Ajusta el índice inicial si tu "Garaje" no es el tercero (índice 2).
  int _currentIndex = 2; // Índice para la barra de navegación: 'Garage'

  // Variable para la posición del tap para el menú de perfil
  Offset? tapPosition;

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
          _profileImageUrl = 'https://i.imgur.com/BoN9kdC.png'; // Restablecer a la imagen por defecto
        });
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'] as String? ?? 'https://i.imgur.com/BoN9kdC.png';
        });
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = '${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
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
          if (mounted) { // Verificar si el widget está montado antes de mostrar SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagen de perfil actualizada.')),
            );
          }
        }
      } catch (e) {
        print('Error al subir imagen o actualizar perfil: $e');
        if (mounted) { // Verificar si el widget está montado antes de mostrar SnackBar
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
                // Navega a la pantalla de inicio de sesión, ajusta la ruta según tu proyecto
                Navigator.of(context).pushReplacementNamed(loginScreenRoute);
              }
            });
          },
        ),
      ],
      color: Colors.black, // Color de fondo del menú
    );
  }


  // Estos métodos _handleLike y _handleComment son placeholders.
  // Asegúrate de que tu PostCard los esté utilizando o elimínalos si no son necesarios.
  void _handleLike(String postId, Map<String, dynamic> postData) {
    print('Like en post: $postId');
    // Implementa la lógica para manejar los likes
  }

  void _handleComment(String postId) {
    print('Comentar en post: $postId');
    // Implementa la lógica para manejar los comentarios
    // Puedes navegar a una pantalla de comentarios, por ejemplo
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
                colors: [
                  Color(0xFF1A0033),
                  Color.fromARGB(255, 60, 0, 100),
                ],
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
        backgroundColor: Colors.transparent, // Transparente para que se vea el gradiente
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
              colors: [
                Color(0xFF1A0033),
                Color.fromARGB(255, 60, 0, 100),
              ],
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
                builder: (context) => const ConfiguracionUser(), // Navegar a la pantalla de configuración
              ),
            );
          },
        ),
        actions: [
          // ¡He movido el botón de subir coche a un FloatingActionButton!
          // IconButton(
          //   icon: const Icon(Icons.directions_car, color: Colors.white),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => const SubirCocheScreen(), // Navegar a la pantalla de subir coche
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // La imagen de perfil y su funcionalidad de tap
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
                radius: 70,
                backgroundColor: Colors.grey[800],
                backgroundImage: NetworkImage(_profileImageUrl),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.purpleAccent,
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Cargando perfil...',
                    style: TextStyle(color: Colors.white),
                  );
                }
                if (snapshot.hasError) {
                  print('Error al cargar perfil de usuario: ${snapshot.error}');
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('Datos de usuario no encontrados.', style: TextStyle(color: Colors.white));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String userName = userData['name'] ?? userData['email'] ?? 'Usuario';
                final String userEmail = userData['email'] ?? 'Email no disponible';

                return Column(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text(
                            'Cargando contadores...',
                            style: TextStyle(color: Colors.white),
                          );
                        }
                        if (snapshot.hasError) {
                          print('Error al cargar contadores en GarageScreen: ${snapshot.error}');
                          return Text(
                            'Error al cargar contadores: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            'Seguidos: 0   Seguidores: 0',
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        final userDoc = snapshot.data!;
                        final data = userDoc.data() as Map<String, dynamic>;
                        final List<dynamic> followersList = data['followers'] ?? [];
                        final List<dynamic> followingList = data['following'] ?? [];

                        final int seguidores = followersList.length;
                        final int seguidos = followingList.length;

                        return Text(
                          'Seguidos: $seguidos   Seguidores: $seguidores',
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Botones de filtro
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton('Todos'),
                  _buildFilterButton('En venta'),
                  _buildFilterButton('Vendido'),
                ],
              ),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  print(
                    'Error al cargar posts del usuario: ${snapshot.error}',
                  );
                  return Center(
                    child: Text(
                      'Error al cargar tus publicaciones: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final filteredDocs =
                    snapshot.data!.docs.where((doc) {
                  if (selectedFilter == 'Todos') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedFilter == 'En venta') {
                    return (data['currentStatus'] == 'En Venta' ||
                        data['currentStatus'] == 'Escucha Ofertas');
                  }
                  if (selectedFilter == 'Vendido') {
                    return data['currentStatus'] == 'Vendido';
                  }
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Icon(Icons.directions_car_filled, size: 80, color: Colors.purple[300]),
                        const SizedBox(height: 20),
                        Text(
                          selectedFilter == 'Todos'
                              ? '¡Parece que aún no has publicado nada!'
                              : 'No hay publicaciones "${selectedFilter.toLowerCase()}" para mostrar.',
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        if (selectedFilter == 'Todos')
                          const SizedBox(height: 10),
                        if (selectedFilter == 'Todos')
                          const Text(
                            'Anímate a vender tu primer vehículo o pieza.',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                      ],
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
                      imageUrl:
                          data['imageUrl'] ?? 'https://via.placeholder.com/150',
                      likes: data['likes'] ?? 0,
                      comments: data['comments'] ?? 0,
                      shares: data['shares'] ?? 0,
                      description: data['description'] ?? '',
                      isLiked: false, // O deberías obtener el estado de like real
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
      // --- NUEVO: Botón de venta flotante ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navegar a la pantalla para añadir/vender un vehículo
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GarageScreen()),
          );
        },
        label: const Text('Vender Mi Vehículo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_business_outlined, size: 28), // Ícono de tienda/venta
        backgroundColor: Colors.lightGreenAccent, // Un color que resalte mucho para la venta
        foregroundColor: const Color(0xFF1A0033), // Color de texto oscuro para contraste
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Colors.white, width: 2), // Borde blanco para mayor destaque
        ),
        elevation: 10, // Sombra para que flote más
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centra el botón abajo
      // --- Integración del CustomBottomNavigationBar ---
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex, // Pasa el índice actual
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Aquí puedes agregar la lógica de navegación real
          // Por ejemplo:
          // if (index == 0) {
          //   Navigator.pushReplacementNamed(context, homeRoute);
          // } else if (index == 1) {
          //   Navigator.pushReplacementNamed(context, searchRoute);
          // } else if (index == 3) {
          //   Navigator.pushReplacementNamed(context, notificationsRoute);
          // } else if (index == 4) {
          //   Navigator.pushReplacementNamed(context, profileRoute);
          // }
        },
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    bool isSelected = selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.purpleAccent : Colors.grey[800],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.purpleAccent : Colors.transparent),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(filter),
      ),
    );
  }
}