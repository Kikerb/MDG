import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importa main.dart si lo necesitas para rutas nombradas, etc.
// import 'package:motor_deal_granada/main.dart';

class PublicGarageScreen extends StatefulWidget {
  final String userId; // ID del usuario cuyo perfil se va a mostrar

  const PublicGarageScreen({super.key, required this.userId});

  @override
  State<PublicGarageScreen> createState() => _PublicGarageScreenState();
}

class _PublicGarageScreenState extends State<PublicGarageScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser; // Obtiene el usuario actualmente logueado
  bool isFollowing = false; // Estado para el botón Seguir/Dejar de Seguir
  int followersCount = 0; // Contador de seguidores del perfil que estamos viendo
  int followingCount = 0; // Contador de seguidos del perfil que estamos viendo

  @override
  void initState() {
    super.initState();
    // Cargamos el estado de seguimiento y los contadores al iniciar la pantalla
    _checkFollowingStatus();
    _fetchCounts();
  }

  // Comprueba si el usuario actual ya sigue al usuario del perfil
  Future<void> _checkFollowingStatus() async {
    if (currentUser == null || currentUser!.uid == widget.userId) {
      // Si es el propio usuario o no hay usuario logueado,
      // no mostramos el botón de seguir/dejar de seguir.
      setState(() {
        isFollowing = false; // Estado que indica que no aplica o es irrelevante
      });
      return;
    }

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (currentUserDoc.exists) {
        // Obtenemos la lista de usuarios a los que sigue el usuario actual
        List<dynamic> following = currentUserDoc['following'] ?? [];
        setState(() {
          // Verificamos si el userId del perfil actual está en la lista de seguidos
          isFollowing = following.contains(widget.userId);
        });
      }
    } catch (e) {
      print('Error al verificar estado de seguimiento: $e');
      // Puedes mostrar un SnackBar si quieres notificar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al verificar estado de seguimiento: $e')),
      );
    }
  }

  // Carga los contadores de seguidores y seguidos para el usuario del perfil
  Future<void> _fetchCounts() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          // Obtenemos las longitudes de las listas de seguidores y seguidos
          followersCount = (userDoc['followers'] as List?)?.length ?? 0;
          followingCount = (userDoc['following'] as List?)?.length ?? 0;
        });
      }
    } catch (e) {
      print('Error al cargar contadores: $e');
    }
  }

  // Lógica para seguir/dejar de seguir a un usuario
  Future<void> _toggleFollow() async {
    if (currentUser == null) {
      // No se puede seguir si no hay usuario logueado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para seguir usuarios.')),
      );
      return;
    }

    final String currentUserId = currentUser!.uid;
    final String targetUserId = widget.userId;

    if (currentUserId == targetUserId) {
      // No se puede seguir a uno mismo, aunque el botón no debería aparecer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes seguirte a ti mismo.')),
      );
      return;
    }

    // Referencias a los documentos de los usuarios
    DocumentReference currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentReference targetUserRef = FirebaseFirestore.instance.collection('users').doc(targetUserId);

    try {
      if (isFollowing) {
        // Lógica para DEJAR DE SEGUIR
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([targetUserId]) // Quita al usuario del perfil de la lista de seguidos del usuario actual
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayRemove([currentUserId]) // Quita al usuario actual de la lista de seguidores del perfil
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dejaste de seguir a este usuario.')),
        );
      } else {
        // Lógica para SEGUIR
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([targetUserId]) // Añade al usuario del perfil a la lista de seguidos del usuario actual
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayUnion([currentUserId]) // Añade al usuario actual a la lista de seguidores del perfil
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ahora sigues a este usuario.')),
        );
      }

      // Actualizar el estado local y los contadores
      setState(() {
        isFollowing = !isFollowing; // Cambia el estado del botón
        _fetchCounts(); // Vuelve a cargar los contadores para que se actualicen en la UI
      });
    } catch (e) {
      print('Error al seguir/dejar de seguir: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la solicitud: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream para obtener los datos del usuario del perfil en tiempo real
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black),
            body: const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black),
            body: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white))),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black),
            body: const Center(child: Text('Usuario no encontrado.', style: TextStyle(color: Colors.white))),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String profileName = userData['name'] ?? userData['email'] ?? 'Usuario';
        final String profileEmail = userData['email'] ?? 'Email no disponible';
        final String profileImageUrl = userData['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

        // Determina si estamos viendo nuestro propio perfil
        final bool isMyOwnProfile = (currentUser != null && currentUser!.uid == widget.userId);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(profileName, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white), // Color para el botón de atrás
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Sección de perfil (similar a tu GarageScreen)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(profileImageUrl),
                      ),
                      const SizedBox(height: 16),
                      Text(profileName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(profileEmail, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatColumn('Seguidores', followersCount),
                          const SizedBox(width: 24),
                          _buildStatColumn('Seguidos', followingCount),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // *** NUEVO: Botón de Seguir/Dejar de Seguir ***
                      if (!isMyOwnProfile) // Solo muestra el botón si NO es el propio perfil
                        SizedBox(
                          width: double.infinity, // Ocupa todo el ancho disponible
                          child: ElevatedButton(
                            onPressed: _toggleFollow, // Llama a la función para seguir/dejar de seguir
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey[800] : Colors.purpleAccent, // Cambia color según el estado
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isFollowing ? 'Dejar de Seguir' : 'Seguir', // Cambia el texto del botón
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),

                      // Otros botones para el dueño del perfil (si fueran relevantes)
                      if (isMyOwnProfile)
                         SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Aquí podrías navegar a una pantalla de edición de perfil o ajustes
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Editar perfil (funcionalidad no implementada)')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent, // Color diferente para "editar"
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Editar Perfil', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Aquí irían las PESTAÑAS para Vehículos y Piezas (similar a tu GarageScreen)
                // y los StreamBuilders correspondientes para mostrar los posts del usuario.
                // Recuerda que estas consultas también deberán usar widget.userId
                // Ejemplo de cómo obtendrías los vehículos de este usuario:
                // StreamBuilder<QuerySnapshot>(
                //   stream: FirebaseFirestore.instance.collection('vehicles')
                //       .where('userId', isEqualTo: widget.userId) // ASUMIMOS UN CAMPO 'userId' EN VEHÍCULOS
                //       .snapshots(),
                //   builder: (context, vehicleSnapshot) {
                //     // ... lógica para mostrar vehículos
                //     return Text('Vehículos del usuario (a implementar)', style: TextStyle(color: Colors.white));
                //   },
                // ),
                const SizedBox(height: 20),
                const Text('Aquí irían los posts de vehículos/piezas del usuario...', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 200), // Espacio para que el scroll sea visible
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}