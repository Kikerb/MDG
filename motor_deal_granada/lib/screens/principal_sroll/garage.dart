import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicle_model.dart'; // Ajusta la ruta a tu VehicleModel
import '../../screens/principal_sroll/Posts.dart'; // Ajusta la ruta a tu PostCard
import '../../screens/principal_sroll/addvehiclescreen.dart'; // La pantalla para añadir vehículos
import '../../screens/principal_sroll/VehicleDetailScreen.dart'; // La pantalla de detalles del vehículo

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  final int _maxGarageSlots = 3; // Define el número máximo de plazas de garaje
  User? _currentUser; // El usuario autenticado

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      // Si no hay usuario logueado, muestra un mensaje o redirige
      return const Scaffold(
        backgroundColor: Color(0xFF1A0033),
        appBar: AppBar(
          title: Text('Mi Garaje', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF1A0033),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text(
            'Inicia sesión para ver tu garaje.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A0033),
      appBar: AppBar(
        title: const Text('Mi Garaje', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A0033),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escucha los vehículos del usuario actual, ordenados por fecha de añadido
        stream:
            FirebaseFirestore.instance
                .collection('vehicles')
                .where('userId', isEqualTo: _currentUser!.uid)
                .orderBy(
                  'addedAt',
                  descending: true,
                ) // Ordena para asignar las plazas consistentemente
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            );
          }
          if (snapshot.hasError) {
            print('Error loading vehicles: ${snapshot.error}');
            return Center(
              child: Text(
                'Error al cargar vehículos: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Si no hay vehículos, muestra solo los botones de añadir
            return _buildGarageGrid(context, []);
          }

          // Convertir los documentos a VehicleModel
          final List<VehicleModel> vehicles =
              snapshot.data!.docs
                  .map((doc) => VehicleModel.fromFirestore(doc))
                  .toList();

          return _buildGarageGrid(context, vehicles);
        },
      ),
    );
  }

  Widget _buildGarageGrid(BuildContext context, List<VehicleModel> vehicles) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columnas por fila
        crossAxisSpacing: 16.0, // Espacio horizontal entre tarjetas
        mainAxisSpacing: 16.0, // Espacio vertical entre tarjetas
        childAspectRatio: 0.7, // Ajusta la relación de aspecto de las tarjetas
      ),
      itemCount: _maxGarageSlots, // Muestra siempre el número máximo de plazas
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
          // Si la plaza está vacía, muestra un botón para añadir un vehículo
          return _buildAddVehicleButton(context, index);
        }
      },
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    // Aquí puedes usar un PostCard simplificado o un widget personalizado
    // para mostrar el vehículo en la plaza de garaje.
    // Usaremos un PostCard para reutilizar tu componente, pero simplificado.

    // Preparar el texto del precio y estado para el PostCard
    String displayPrice = 'No disponible';
    if (vehicle.currentStatus == 'En Venta' && vehicle.price != null) {
      displayPrice =
          '${vehicle.price!.toStringAsFixed(0)} ${vehicle.currency ?? ''}';
    } else if (vehicle.currentStatus == 'Escucha Ofertas') {
      displayPrice = 'Escucha Ofertas';
    } else {
      displayPrice =
          vehicle.currentStatus; // Mostrar el estado si no es "En Venta"
    }

    return GestureDetector(
      onTap: () {
        // Al tocar el vehículo, navega a la pantalla de detalles
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
          ),
        );
      },
      child: PostCard(
        // Propiedades de PostCard (simplificadas para la vista de garaje)
        postId: vehicle.id,
        username: vehicle.userId, // O el nombre real del propietario
        imageUrl: vehicle.mainImageUrl,
        description: '${vehicle.brand} ${vehicle.model}', // Descripción corta
        likes: 0,
        comments: 0,
        shares: 0,
        isLiked: false, // Acciones no son relevantes aquí
        onLike: () {},
        onComment: () {},
        onShare: null, // Deshabilitar acciones
        // Mostrar solo lo relevante para la plaza del garaje
        showUsername: false, // No necesitamos el avatar/nombre de usuario aquí
        showActions:
            false, // No necesitamos botones de like/comentario/compartir aquí
        showPrice: true, // Queremos mostrar el precio
        price: displayPrice,
        showStatus: true, // Queremos mostrar el estado
        status: vehicle.currentStatus,
      ),
    );
  }

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
          // Si AddVehicleScreen se hace con pop, el StreamBuilder refrescará la UI
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          // Opcional: Si necesitas hacer algo específico después de añadir,
          // puedes usar await y verificar si el vehículo se añadió (ej. retornando true)
        },
        borderRadius: BorderRadius.circular(12.0),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 60, color: Colors.white70),
            SizedBox(height: 10),
            Text(
              'Añadir Vehículo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Plaza libre #${slotIndex + 1}',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
