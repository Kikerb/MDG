import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart'; // Importa main.dart para las rutas nombradas (asumiendo que tienes rutas nombradas como loginRoute)
import '../../widgets/bottom_navigation_bar.dart'; // Importa tu barra de navegación

import '../../screens/principal_sroll/ConfiguracionUser.dart'; // Ajusta la ruta si es necesario
import '../../models/vehicle_model.dart'; // Ajusta la ruta a tu VehicleModel
import '../../screens/principal_sroll/addvehiclescreen.dart'; // La pantalla para añadir vehículos
import '../../screens/principal_sroll/vehicle_detail_screen.dart'; // La pantalla de detalles del vehículo

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  // Define el número máximo de plazas de garaje
  final int _maxGarageSlots = 3;
  User? _currentUser; // El usuario autenticado

  // Usamos _currentIndex para el CustomBottomNavigationBar.
  // Ajusta el índice inicial si tu "Garaje" no es el tercero (índice 2).
  int _currentIndex = 2; // Índice para la barra de navegación: 'Garage'


  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    // Escuchar cambios de autenticación para actualizar la UI si el usuario cierra sesión
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && _currentUser != null) {
        // El usuario ha cerrado sesión, redirige a la pantalla de login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(loginScreenRoute);
        }
      }
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay usuario logueado, muestra un mensaje o redirige
    if (_currentUser == null) {
      // Se recomienda redirigir directamente en authStateChanges para evitar flashes
      return const Scaffold(
        backgroundColor: Color(0xFF1A0033),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    final userId = _currentUser!.uid;
    final userEmail = _currentUser!.email ?? 'Usuario desconocido';

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
        // No hay acciones en la appbar para subir coche, ya que usamos FAB
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'GARAGE',
              style: TextStyle(
                fontSize: 28,
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            // StreamBuilder para los vehículos del usuario
            StreamBuilder<QuerySnapshot>(
              // Escucha los vehículos del usuario actual, ordenados por fecha de añadido
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('userId', isEqualTo: userId)
                  .orderBy('addedAt', descending: true) // Ordena para asignar las plazas consistentemente
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }
                if (snapshot.hasError) {
                  print('Error al cargar vehículos: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error al cargar vehículos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                  );
                }

                // Convertir los documentos a VehicleModel
                final List<VehicleModel> vehicles = snapshot.data!.docs
                    .map((doc) => VehicleModel.fromFirestore(doc))
                    .toList();

                // Construir la cuadrícula de garaje con los vehículos y las plazas vacías
                return _buildGarageGrid(context, vehicles);
              },
            ),
          ],
        ),
      ),
      // Botón flotante para añadir un vehículo

      // Integración del CustomBottomNavigationBar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex, // Pasa el índice actual
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Aquí puedes agregar la lógica de navegación real a tus otras pantallas
          // Ejemplo:
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

  // Widget para construir la cuadrícula del garaje (vehículos + plazas vacías)
  Widget _buildGarageGrid(BuildContext context, List<VehicleModel> vehicles) {
    return GridView.builder(
      shrinkWrap: true, // Importante para que el GridView no ocupe todo el espacio y permita el SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll interno del GridView
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

  // Widget para la tarjeta de un vehículo en el garaje
  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle) {
    // Preparar el texto del precio y estado para la tarjeta
    String displayPrice = 'N/A';
    if (vehicle.currentStatus == 'En Venta' && vehicle.price != null) {
      displayPrice = '${vehicle.price!.toStringAsFixed(0)} €'; // Asume euros, ajusta si es necesario
    } else if (vehicle.currentStatus == 'Escucha Ofertas') {
      displayPrice = 'Escucha Ofertas';
    } else {
      displayPrice = vehicle.currentStatus; // Mostrar el estado si no es "En Venta"
    }

    return Card(
      color: Colors.grey[900], // Fondo oscuro para la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: Image.network(
                  vehicle.mainImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
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
                        child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
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
                      color: vehicle.currentStatus == 'Vendido' ? Colors.redAccent : Colors.lightGreenAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estado: ${vehicle.currentStatus}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
          // Si AddVehicleScreen se hace con pop, el StreamBuilder refrescará la UI
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
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