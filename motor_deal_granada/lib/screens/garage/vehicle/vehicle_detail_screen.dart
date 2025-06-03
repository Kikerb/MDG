import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importa Firebase Storage
import '../../../models/post_model.dart';
import '../../../models/vehicle_model.dart';
import '../../principal_sroll/post/Posts.dart'; // Importa tu PostCard y quizás la lógica de manejo de posts

class VehicleDetailsScreen extends StatefulWidget {
  // Cambiamos el constructor para recibir el VehicleModel
  // El vehicleId es opcional si ya tenemos el objeto VehicleModel
  final VehicleModel vehicle; // El vehículo que se pasa desde la pantalla anterior
  final String? vehicleId; // Opcional: para recargar si es necesario

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle, // Ahora se requiere el objeto VehicleModel
    this.vehicleId, // El vehicleId ahora es opcional
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _handleLike(String postId) async {
    // Implementa tu lógica de "me gusta" para un post
    // Aquí puedes acceder a Firebase Firestore para actualizar el contador de likes
    print('Like manejado para el post $postId');
  }

  void _handleComment(String postId) {
    // Implementa la navegación a la pantalla de comentarios
    print('Comentario manejado para el post $postId');
    // Ejemplo de navegación a una pantalla de comentarios:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId)),
    // );
  }

  void _handleShare(String postId) {
    // Implementa la lógica de compartir un post
    print('Compartir manejado para el post $postId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Detalles del Vehículo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: Implementar navegación a la pantalla de edición del vehículo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de editar vehículo aún no implementada.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // TODO: Implementar lógica para eliminar el vehículo
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Usamos el vehicleId si lo pasamos, si no, el ID del objeto VehicleModel
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId ?? widget.vehicle.id) // Usa widget.vehicleId si existe, sino widget.vehicle.id
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar los detalles del vehículo: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Vehículo no encontrado.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final vehicle = VehicleModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Detalles del Vehículo
                if (vehicle.mainImageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 250, // Altura de la imagen principal
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(vehicle.mainImageUrl), // Usar ! aquí para asegurar que no es nulo
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container( // Placeholder si no hay imagen
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.directions_car, size: 100, color: Colors.white54),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model} (${vehicle.year})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: ${vehicle.vehicleType}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Kilometraje: ${vehicle.mileage.toStringAsFixed(0)} km',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Combustible: ${vehicle.fuelType}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                      if (vehicle.price != null &&
                          (vehicle.currentStatus == 'En Venta' ||
                              vehicle.currentStatus == 'Escucha Ofertas'))
                        Text(
                          'Precio: ${vehicle.price!.toStringAsFixed(0)} ${vehicle.currency ?? ''}',
                          style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Estado: ${vehicle.currentStatus}',
                        style: TextStyle(
                          color: vehicle.currentStatus == 'En Venta'
                              ? Colors.green
                              : vehicle.currentStatus == 'Vendido'
                                  ? Colors.red
                                  : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vehicle.description,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                      ),
                      if (vehicle.vin != null && vehicle.vin!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'VIN: ${vehicle.vin}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white, thickness: 0.2),
                      const Text(
                        'Posts de este vehículo:',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Sección de Posts del Vehículo
                // Aquí usamos StreamBuilder para obtener los posts relacionados con este vehículo
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('vehicleId', isEqualTo: vehicle.id) // Usamos vehicle.id aquí
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.purpleAccent));
                    }
                    if (postsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar los posts: ${postsSnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!postsSnapshot.hasData ||
                        postsSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Aún no hay posts para este vehículo.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: postsSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final postDoc = postsSnapshot.data!.docs[index];
                        final postData = postDoc.data() as Map<String, dynamic>;

                        // Asume que tu PostCard tiene los campos necesarios
                        // Y que necesitas el UID del usuario para determinar si ha dado like
                        // (esto es un placeholder, deberías adaptar PostCard para manejar likes dinámicamente)
                        final String? userId = FirebaseAuth.instance.currentUser?.uid; // Puede ser nulo

                        return PostCard(
                          postId: postDoc.id,
                          username: postData['username'] ?? 'Usuario Desconocido',
                          imageUrl: postData['imageUrl'] ?? 'https://via.placeholder.com/150',
                          likes: postData['likesCount'] ?? 0,
                          comments: postData['commentsCount'] ?? 0,
                          shares: postData['sharesCount'] ?? 0,
                          description: postData['description'] ?? '',
                          isLiked: (postData['likedBy'] as List<dynamic>?)?.contains(userId) ?? false,
                          onLike: () => _handleLike(postDoc.id),
                          onComment: () => _handleComment(postDoc.id),
                          onShare: () => _handleShare(postDoc.id),
                          showPrice: false,
                          status: '',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Eliminar Vehículo', style: TextStyle(color: Colors.white)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Estás seguro de que quieres eliminar este vehículo de tu garaje? Esta acción no se puede deshacer y también eliminará todos los posts asociados a él.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.purpleAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await _deleteVehicle();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVehicle() async {
    try {
      // 1. Eliminar todos los posts asociados al vehículo
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('vehicleId', isEqualTo: widget.vehicle.id) // Usar widget.vehicle.id
          .get();

      for (final doc in postsQuery.docs) {
        await FirebaseFirestore.instance.collection('posts').doc(doc.id).delete();
      }

      // 2. Eliminar la imagen principal del vehículo de Storage
      // Solo intenta eliminar si hay una URL de imagen válida
      if (widget.vehicle.mainImageUrl.isNotEmpty) {
        try {
          final vehicleRef = FirebaseStorage.instance.refFromURL(widget.vehicle.mainImageUrl); // Usar widget.vehicle.mainImageUrl!
          await vehicleRef.delete();
        } catch (e) {
          print('Error al eliminar imagen de Storage: $e');
          // No bloqueamos la eliminación del vehículo si falla la imagen
        }
      }

      // 3. Eliminar el documento del vehículo de Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id) // Usar widget.vehicle.id
          .delete();

      // 4. Decrementar garageSlotsUsed en el perfil del usuario
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'garageSlotsUsed': FieldValue.increment(-1)});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo y sus posts eliminados con éxito.')),
      );
      // Regresar a la pantalla anterior (GarageScreen)
      // Asegúrate de que el pop se haga DESPUÉS de que todo se haya eliminado con éxito
      if (mounted) { // Comprueba si el widget sigue en el árbol antes de navegar
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error al eliminar vehículo: $e');
      if (mounted) { // Comprueba si el widget sigue en el árbol antes de mostrar el SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar vehículo: $e')),
        );
      }
    }
  }
}