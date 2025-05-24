import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String searchText = '';
  int _currentIndex = 1; // Índice de la pestaña actual (Buscar)
  String selectedFilter = 'usuarios'; // Filtro actual: usuarios, vehiculos o piezas

  @override
  Widget build(BuildContext context) {
    // Ajustar colección y placeholder según filtro
    String collectionName = 'users';
    String hintText = 'Buscar usuarios por email...';
    if (selectedFilter == 'vehiculos') {
      collectionName = 'vehicles';
      hintText = 'Buscar vehículos por modelo...';
    } else if (selectedFilter == 'piezas') {
      collectionName = 'parts';
      hintText = 'Buscar piezas por nombre...';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),  // <-- margen pequeño arriba
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
              stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }

                final allDocs = snapshot.data!.docs;

                if (searchText.isEmpty) {
                  return Center(
                    child: Text(
                      'Ingresa texto para buscar $selectedFilter.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  switch (selectedFilter) {
                    case 'usuarios':
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return email.contains(searchText.toLowerCase());
                    case 'vehiculos':
                      final modelo = (data['modelo'] ?? '').toString().toLowerCase();
                      return modelo.contains(searchText.toLowerCase());
                    case 'piezas':
                      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                      return nombre.contains(searchText.toLowerCase());
                    default:
                      return false;
                  }
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron $selectedFilter.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A0033),
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;

          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed(garageScreenRoute);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: 'Garage',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filterKey, String label) {
    final isSelected = filterKey == selectedFilter;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterKey;
          searchText = '';
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

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>? ?? {};
    final username = data['username'] ?? 'Sin nombre';
    final email = data['email'] ?? '';
    final profileImage =
        data['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profileImage),
        radius: 24,
      ),
      title: Text(username, style: const TextStyle(color: Colors.white)),
      subtitle: Text(email, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver perfil de $username')),
        );
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
