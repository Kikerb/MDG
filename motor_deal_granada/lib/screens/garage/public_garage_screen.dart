import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/vehicle_model.dart';
import '../../models/part_model.dart';
import '../../repository/part_repository.dart';
import '../garage/vehicle/vehicle_detail_screen.dart';
import '../market/part_detail_screen.dart';

class PublicGarageScreen extends StatefulWidget {
  final String userId;

  const PublicGarageScreen({super.key, required this.userId});

  @override
  State<PublicGarageScreen> createState() => _PublicGarageScreenState();
}

class _PublicGarageScreenState extends State<PublicGarageScreen> with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final PartRepository _partRepository = PartRepository();

  late TabController _tabController;

  bool isFollowing = false;
  int followersCount = 0;
  int followingCount = 0;
  int vehicleCount = 0;
  int partCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFollowingStatus();
    _fetchCounts();
  }

  // Elimina el TabController cuando el widget se elimina del árbol de widgets
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowingStatus() async {
    if (currentUser == null || currentUser!.uid == widget.userId) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        final List following = doc['following'] ?? [];
        setState(() => isFollowing = following.contains(widget.userId));
      }
    } catch (e) {
      print("Error al verificar el estado de seguimiento: $e");
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = doc.data();
      if (data != null) {
        final vehicleSnap = await FirebaseFirestore.instance
            .collection('vehicles')
            .where('userId', isEqualTo: widget.userId)
            .get();

        final partSnap = await FirebaseFirestore.instance
            .collection('parts')
            .where('userId', isEqualTo: widget.userId)
            .get();

        if (mounted) { // Asegúrate de que el widget todavía esté montado antes de llamar a setState
          setState(() {
            followersCount = (data['followers'] as List?)?.length ?? 0;
            followingCount = (data['following'] as List?)?.length ?? 0;
            vehicleCount = vehicleSnap.size;
            partCount = partSnap.size;
          });
        }
      }
    } catch (e) {
      print("Error al obtener los recuentos: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (currentUser == null || currentUser!.uid == widget.userId) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    try {
      if (isFollowing) {
        await userRef.update({'following': FieldValue.arrayRemove([widget.userId])});
        await targetRef.update({'followers': FieldValue.arrayRemove([currentUser!.uid])});
      } else {
        await userRef.update({'following': FieldValue.arrayUnion([widget.userId])});
        await targetRef.update({'followers': FieldValue.arrayUnion([currentUser!.uid])});
      }

      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
          _fetchCounts(); // Vuelve a obtener los recuentos para actualizar la UI inmediatamente
        });
      }
    } catch (e) {
      print("Error al cambiar el estado de seguimiento: $e");
      // Opcionalmente, muestra un SnackBar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar el estado de seguimiento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = currentUser?.uid == widget.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Garaje Público", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuario no encontrado.', style: TextStyle(color: Colors.white70)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = data['username'] ?? 'Usuario';
          final profileImageUrl = data['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

          // Reevalúa canViewContent basándose en el último estado de seguimiento
          // Esto asegura que si el usuario sigue/deja de seguir, la vista de contenido se actualiza
          final canViewContent = isOwnProfile || isFollowing;

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildProfileHeader(username, profileImageUrl, isOwnProfile, canViewContent),
              const SizedBox(height: 10),
              // Solo muestra TabBar si el contenido se puede ver
              if (canViewContent) _buildTabBar(),
              // Usa un widget Expanded para asegurar que TabBarView ocupe el espacio disponible
              if (canViewContent)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVehicleTab(),
                      _buildPartTab(),
                    ],
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Debes seguir a este usuario para ver su garaje.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String username, String imageUrl, bool isOwnProfile, bool canViewContent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Solo muestra las estadísticas si el contenido se puede ver o es el propio perfil
                if (canViewContent || isOwnProfile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("SEGUIDORES", followersCount),
                      _buildStatColumn("SEGUIDOS", followingCount),
                      _buildStatColumn("VEHÍCULOS", vehicleCount),
                      _buildStatColumn("PIEZAS", partCount),
                    ],
                  ),
                const SizedBox(height: 8),
                if (!isOwnProfile)
                  ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey : Colors.purpleAccent,
                      minimumSize: const Size(double.infinity, 36), // Haz que el botón ocupe todo el ancho
                    ),
                    child: Text(
                      isFollowing ? 'Siguiendo' : 'Seguir',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar( // El TabBar necesita un controlador
      controller: _tabController,
      indicatorColor: Colors.purpleAccent,
      labelColor: Colors.purpleAccent,
      unselectedLabelColor: Colors.white70,
      tabs: const [
        Tab(icon: Icon(Icons.directions_car), text: 'Vehículos'),
        Tab(icon: Icon(Icons.build), text: 'Piezas'),
      ],
    );
  }

  Widget _buildVehicleTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Sin vehículos.', style: TextStyle(color: Colors.white70)));
        }

        final List<VehicleModel> vehicles = snapshot.data!.docs
            .map((doc) => VehicleModel.fromFirestore(doc))
            .where((v) => v.isActive) // Asumiendo que isActive es una propiedad en tu VehicleModel
            .toList();

        if (vehicles.isEmpty) {
          return const Center(child: Text('Sin vehículos activos.', style: TextStyle(color: Colors.white70)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: vehicle)),
                );
              },
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          vehicle.mainImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('${vehicle.year} - ${vehicle.fuelType}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(vehicle.currentStatus, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartTab() {
    return FutureBuilder<List<PartModel>>(
      future: _partRepository.fetchPartsByUser(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sin piezas.', style: TextStyle(color: Colors.white70)));
        }

        final parts = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final part = parts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PartDetailScreen(part: part)),
                );
              },
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          part.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(part.partName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}