import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage
import '../../../models/vehicle_model.dart';
import '../../principal_sroll/post/Posts.dart'; // PostCard y lógica posts

class VehicleDetailsScreen extends StatefulWidget {
  final VehicleModel vehicle;
  final String? vehicleId;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    this.vehicleId,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _handleLike(String postId) async {
    print('Like manejado para el post $postId');
  }

  void _handleComment(String postId) {
    print('Comentario manejado para el post $postId');
  }

  void _handleShare(String postId) {
    print('Compartir manejado para el post $postId');
  }

  Future<void> _sendOffer(double offerAmount) async {
    if (currentUser == null) return;

    final ownerId = widget.vehicle.ownerId;
    final chatId = _generateChatId(currentUser!.uid, ownerId);

    final messageData = {
      'senderId': currentUser!.uid,
      'receiverId': ownerId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'offer',
      'offerAmount': offerAmount,
      'vehicleId': widget.vehicle.id,
      'vehicleBrand': widget.vehicle.brand,
      'vehicleModel': widget.vehicle.model,
      'vehicleYear': widget.vehicle.year,
      'vehicleImageUrl': widget.vehicle.mainImageUrl,
      'status': 'pending',
    };

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Actualiza el último mensaje y timestamp en el chat para listas
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'users': [currentUser!.uid, ownerId],
        'lastMessage': 'Oferta enviada: $offerAmount',
        'lastTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oferta enviada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la oferta: $e')),
        );
      }
    }
  }

  Future<void> _showOfferDialog() async {
    final TextEditingController offerController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Hacer una oferta', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: offerController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Introduce tu oferta',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.purpleAccent)),
            ),
            TextButton(
              onPressed: () {
                final input = offerController.text.trim();
                if (input.isNotEmpty) {
                  final offerAmount = double.tryParse(input);
                  if (offerAmount != null && offerAmount > 0) {
                    Navigator.of(context).pop();
                    _sendOffer(offerAmount);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Introduce un número válido')),
                    );
                  }
                }
              },
              child: const Text('Enviar', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de editar vehículo aún no implementada.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId ?? widget.vehicle.id)
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
                if (vehicle.mainImageUrl.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(vehicle.mainImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
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
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Kilometraje: ${vehicle.mileage.toStringAsFixed(0)} km',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Combustible: ${vehicle.fuelType}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      if (vehicle.price != null &&
                          (vehicle.currentStatus == 'En Venta' || vehicle.currentStatus == 'Escucha Ofertas'))
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
                        style: const TextStyle(color: Colors.white, fontSize: 15),
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

                      // Botón hacer oferta si aplica
                      if (vehicle.currentStatus == 'En Venta' || vehicle.currentStatus == 'Escucha Ofertas')
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            ),
                            onPressed: () {
                              _showOfferDialog();
                            },
                            child: const Text(
                              'Hacer una oferta',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Posts del vehículo
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('vehicleId', isEqualTo: vehicle.id)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }
                    if (postsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar los posts: ${postsSnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!postsSnapshot.hasData || postsSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Aún no hay posts para este vehículo.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
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

                        final String? userId = FirebaseAuth.instance.currentUser?.uid;

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
      barrierDismissible: false, 
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
                Navigator.of(context).pop(); 
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
      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('vehicleId', isEqualTo: widget.vehicle.id)
          .get();

      for (final doc in postsQuery.docs) {
        await FirebaseFirestore.instance.collection('posts').doc(doc.id).delete();
      }

      if (widget.vehicle.mainImageUrl.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(widget.vehicle.mainImageUrl);
        await ref.delete();
      }

      await FirebaseFirestore.instance.collection('vehicles').doc(widget.vehicle.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo eliminado correctamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el vehículo: $e')),
        );
      }
    }
  }

  // Función para generar el ID del chat entre dos usuarios ordenados alfabéticamente
  String _generateChatId(String user1, String user2) {
    final ids = [user1, user2]..sort();
    return ids.join('_');
  }
}
