import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart'; // Asegúrate de que estas rutas sean correctas

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String searchText = '';
  int _currentIndex = 1; // Índice de la pestaña actual (Buscar)
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

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>? ?? {};
    // Asumimos que siempre habrá un 'email' para los usuarios buscados.
    // Si 'username' no existe, este campo se puede omitir o inicializar como vacío.
    final username = data['username'] ?? ''; // Si existe un 'username', se usará, si no, vacío.
    final email = data['email'] ?? 'Email no disponible'; // Valor por defecto si 'email' no existe

    // Decide qué mostrar como título principal: si hay un username, lo mostramos, si no, el email.
    final titleText = username.isNotEmpty ? username : email;
    // El subtítulo siempre será el email (si está disponible)
    final subtitleText = email;

    return ListTile(
      leading: CircleAvatar(
        // Asegúrate de que 'profileImageUrl' sea el campo correcto en tu documento
        backgroundImage: NetworkImage(data['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png'),
        radius: 24,
      ),
      title: Text(titleText, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitleText, style: const TextStyle(color: Colors.white54)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver perfil de ${titleText}')),
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