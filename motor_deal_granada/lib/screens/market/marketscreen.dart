import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation_bar.dart'; // Importa tu barra de navegación personalizada
import '../../main.dart'; // Importa main.dart para las rutas (si es necesario para la navegación de la barra inferior)

// Esta es una pantalla de prueba para el mercado.
// Puedes expandir su funcionalidad y diseño más adelante.

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  // El índice para la barra de navegación inferior.
  // Asumimos que 'Mercado' o 'Carrito' corresponde al índice 3 en CustomBottomNavigationBar.
  int _currentIndex = 3; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro para la pantalla de mercado
      appBar: AppBar(
        title: const Text(
          'Mercado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent, // Transparente para el gradiente
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A0033), // Color púrpura oscuro
                Color.fromARGB(255, 60, 0, 100), // Color púrpura ligeramente más claro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront, // Un icono que representa una tienda o mercado
              size: 100,
              color: Colors.purpleAccent.withOpacity(0.7), // Color de acento
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido al Mercado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí podrás explorar vehículos y piezas en venta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            // Puedes añadir un botón para simular la carga de productos
            ElevatedButton.icon(
              onPressed: () {
                // Lógica de prueba: por ahora, solo un mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cargando productos del mercado...')),
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Cargar Productos',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, // Color del botón
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      // Añadir el CustomBottomNavigationBar aquí
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // La lógica de navegación real se maneja dentro de CustomBottomNavigationBar
          // No es necesario duplicar la navegación aquí si la barra ya lo hace.
        },
      ),
    );
  }
}