import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:motor_deal_granada/screens/garage/public_garage_screen.dart';

import '../../main.dart'; // Asegúrate de que estas rutas sean correctas
import '../../widgets/bottom_navigation_bar.dart'; // Importa CustomBottomNavigationBar

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String searchText = '';
  // El índice para la barra de navegación inferior.
  // Asumimos que 'Buscar' corresponde al índice 1 en CustomBottomNavigationBar.
  int _currentIndex = 1; 
  String selectedFilter = 'usuarios'; // Filtro actual: usuarios, vehiculos o piezas

  // Función para construir el stream de la consulta de Firebase
  Stream<QuerySnapshot> _getSearchStream() {
    String fieldToSearch;
    String collectionName;

    switch (selectedFilter) {
      case 'usuarios':
        collectionName = 'users';
        fieldToSearch = 'email'; // Búsqueda explícita por 'email' para usuarios
        break;
      case 'vehiculos':
        collectionName = 'vehicles';
        fieldToSearch = 'modelo'; // Campo por el que buscar en vehículos
        break;
      case 'piezas':
        collectionName = 'parts';
        fieldToSearch = 'nombre'; // Campo por el que buscar en piezas
        break;
      default:
        collectionName = 'users'; // Por defecto
        fieldToSearch = 'email';
    }

    // Si el texto de búsqueda está vacío, puedes decidir qué mostrar.
    // Aquí, se mostrarán los primeros 20 resultados de la colección.
    if (searchText.isEmpty) {
      return FirebaseFirestore.instance.collection(collectionName).limit(20).snapshots();
    }

    // Construye la consulta de Firebase para la búsqueda por prefijo
    // Aseguramos que el texto de búsqueda esté en minúsculas para coincidir con el almacenamiento
    // (asumiendo que los emails se guardan en minúsculas en Firestore para la búsqueda)
    final lowerCaseSearchText = searchText.toLowerCase();

    return FirebaseFirestore.instance
        .collection(collectionName)
        .where(fieldToSearch, isGreaterThanOrEqualTo: lowerCaseSearchText)
        .where(fieldToSearch, isLessThanOrEqualTo: lowerCaseSearchText + '\uf8ff')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Ajustar placeholder según filtro
    String hintText;
    if (selectedFilter == 'vehiculos') {
      hintText = 'Buscar vehículos por modelo...';
    } else if (selectedFilter == 'piezas') {
      hintText = 'Buscar piezas por nombre...';
    } else {
      hintText = 'Buscar usuarios por email...';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white54),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.trim();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros (botones redondos pequeños en fila)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterButton('usuarios', 'U'),
                const SizedBox(width: 8),
                _buildFilterButton('vehiculos', 'V'),
                const SizedBox(width: 8),
                _buildFilterButton('piezas', 'P'),
              ],
            ),
          ),
          // Listado con scroll que ocupa el espacio restante
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSearchStream(), // ¡Aquí usamos el nuevo stream!
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }

                if (snapshot.hasError) {
                  print('Error al cargar resultados: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error al cargar resultados: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Solo mostrar mensaje si no hay resultados Y hay texto de búsqueda
                if (docs.isEmpty && searchText.isNotEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron $selectedFilter con ese nombre.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                // Si no hay texto de búsqueda, pero no hay resultados, mostrar un mensaje más genérico
                if (docs.isEmpty && searchText.isEmpty) {
                    return Center(
                    child: Text(
                      'Ingresa texto para buscar $selectedFilter.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    switch (selectedFilter) {
                      case 'usuarios':
                        return _buildUserTile(doc);
                      case 'vehiculos':
                        return _buildVehicleTile(doc);
                      case 'piezas':
                        return _buildPartTile(doc);
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      // REEMPLAZO DEL BottomNavigationBar por CustomBottomNavigationBar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // La lógica de navegación real se maneja dentro de CustomBottomNavigationBar
          // No es necesario duplicar la navegación aquí.
        },
      ),
    );
  }

  Widget _buildFilterButton(String filterKey, String label) {
    final isSelected = filterKey == selectedFilter;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterKey;
          searchText = ''; // Limpiar el texto de búsqueda al cambiar de filtro
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent : Colors.grey[800],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // En tu BuscarScreen
// En tu BuscarScreen
Widget _buildUserTile(QueryDocumentSnapshot user) {
  final data = user.data() as Map<String, dynamic>? ?? {};
  final String email = (data['email'] is String) ? data['email'] : 'Email no disponible';
  final String username = (data['username'] is String) ? data['username'] : '';
  final String titleText = username.isNotEmpty ? username : email;
  final String subtitleText = email;
  final String profileImageUrl = (data['profileImageUrl'] is String)
      ? data['profileImageUrl']
      : 'https://i.imgur.com/BoN9kdC.png';

  return ListTile(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(profileImageUrl),
      radius: 24,
    ),
    title: Text(titleText, style: const TextStyle(color: Colors.white)),
    subtitle: Text(subtitleText, style: const TextStyle(color: Colors.white54)),
    onTap: () {
      // *** CAMBIO AQUÍ ***
      // Navegar a la nueva pantalla PublicGarageScreen, pasándole el ID del usuario
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PublicGarageScreen(userId: user.id), // 'user.id' es el UID del usuario
        ),
      );
      // O, si defines una ruta nombrada para PublicGarageScreen:
      // Navigator.of(context).pushNamed(publicGarageScreenRoute, arguments: user.id);
    },
  );
}

  Widget _buildVehicleTile(QueryDocumentSnapshot vehicle) {
    final data = vehicle.data() as Map<String, dynamic>? ?? {};
    final modelo = data['modelo'] ?? 'Sin modelo';
    final marca = data['marca'] ?? 'Sin marca';
    final imagen =
        data['imagenUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

    return ListTile(
      leading: Image.network(imagen, width: 50, height: 50, fit: BoxFit.cover),
      title: Text('$marca $modelo', style: const TextStyle(color: Colors.white)),
      subtitle: const Text('Vehículo', style: TextStyle(color: Colors.white54)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver vehículo $marca $modelo')),
        );
      },
    );
  }

  Widget _buildPartTile(QueryDocumentSnapshot part) {
    final data = part.data() as Map<String, dynamic>? ?? {};
    final nombre = data['nombre'] ?? 'Sin nombre';
    final descripcion = data['descripcion'] ?? '';
    final imagen =
        data['imagenUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

    return ListTile(
      leading: Image.network(imagen, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(nombre, style: const TextStyle(color: Colors.white)),
      subtitle: Text(descripcion, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver pieza: $nombre')),
        );
      },
    );
  }
}