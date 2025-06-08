import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicle_model.dart';
import 'vehicle/vehicle_detail_screen.dart';

class PublicGarageScreen extends StatefulWidget {
  final String userId; // ID del usuario cuyo garaje se va a mostrar

  const PublicGarageScreen({super.key, required this.userId});

  @override
  State<PublicGarageScreen> createState() => _PublicGarageScreenState();
}

class _PublicGarageScreenState extends State<PublicGarageScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
    _fetchCounts();
  }

  Future<void> _checkFollowingStatus() async {
    if (currentUser == null || currentUser!.uid == widget.userId) {
      setState(() => isFollowing = false);
      return;
    }

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (currentUserDoc.exists) {
        List<dynamic> following = currentUserDoc['following'] ?? [];
        setState(() => isFollowing = following.contains(widget.userId));
      }
    } catch (e) {
      print('Error al verificar seguimiento: $e');
    }
  }

  Future<void> _fetchCounts() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          followersCount = (userDoc['followers'] as List?)?.length ?? 0;
          followingCount = (userDoc['following'] as List?)?.length ?? 0;
        });
      }
    } catch (e) {
      print('Error al cargar contadores: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para seguir usuarios.')),
      );
      return;
    }

    final String currentUserId = currentUser!.uid;
    final String targetUserId = widget.userId;

    if (currentUserId == targetUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes seguirte a ti mismo.')),
      );
      return;
    }

    DocumentReference currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentReference targetUserRef = FirebaseFirestore.instance.collection('users').doc(targetUserId);

    try {
      if (isFollowing) {
        await currentUserRef.update({
          'following': FieldValue.arrayRemove([targetUserId])
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayRemove([currentUserId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dejaste de seguir a este usuario.')),
        );
      } else {
        await currentUserRef.update({
          'following': FieldValue.arrayUnion([targetUserId])
        });
        await targetUserRef.update({
          'followers': FieldValue.arrayUnion([currentUserId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ahora sigues a este usuario.')),
        );
      }

      setState(() {
        isFollowing = !isFollowing;
        _fetchCounts();
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Usuario no encontrado.'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String profileName = userData['username'] ?? userData['email'] ?? 'Usuario';
        final String profileEmail = userData['email'] ?? 'Email no disponible';
        final String profileImageUrl = userData['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

        final bool isMyOwnProfile = (currentUser != null && currentUser!.uid == widget.userId);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(profileName, style: const TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 60, backgroundImage: NetworkImage(profileImageUrl)),
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
                      if (!isMyOwnProfile)
                        ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[800] : Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(isFollowing ? 'Dejar de Seguir' : 'Seguir', style: const TextStyle(fontSize: 18)),
                        ),
                      const SizedBox(height: 24),
                      _buildPublicGarage(widget.userId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicGarage(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').where('userId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error al cargar vehículos: ${snapshot.error}"));

        final List<DocumentSnapshot> vehicles = snapshot.data!.docs;
        return vehicles.isEmpty
            ? const Center(child: Text("Este usuario no tiene vehículos en su garaje.", style: TextStyle(color: Colors.white70, fontSize: 18)))
            : _buildVehicleGrid(vehicles);
      },
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
Widget _buildVehicleGrid(List<DocumentSnapshot> documents) {
  List<VehicleModel> vehicles = documents
      .map((doc) => VehicleModel.fromFirestore(doc))
      .where((v) => v.isActive) // Solo mostrar vehículos activos
      .toList();

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: vehicles.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.75,
    ),
    itemBuilder: (context, index) {
      final vehicle = vehicles[index];
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
            ),
          );
        },
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    vehicle.mainImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 50, color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${vehicle.year} • ${vehicle.fuelType}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (vehicle.currentStatus == 'En Venta' && vehicle.price != null)
                      Text(
                        '${vehicle.price!.toStringAsFixed(2)} ${vehicle.currency ?? ''}',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      )
                    else
                      Text(
                        vehicle.currentStatus,
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}