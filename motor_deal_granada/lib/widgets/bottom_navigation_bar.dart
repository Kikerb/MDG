import 'package:flutter/material.dart';
import '../main.dart'; // Importa main.dart para las rutas

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // Índice del ítem actualmente seleccionado
  final Function(int) onItemSelected; // Callback para cuando se selecciona un ítem

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1A0033), // Fondo de la barra púrpura oscuro
      selectedItemColor: Colors.purpleAccent, // Color del icono seleccionado
      unselectedItemColor: Colors.white, // Color del icono no seleccionado
      currentIndex: currentIndex, // Usa el currentIndex pasado como parámetro
      onTap: (index) {
        // Ejecuta el callback proporcionado por el padre
        onItemSelected(index);

        // Lógica de navegación basada en el índice
        switch (index) {
          case 0:
            // Inicio
            // Solo navega si no estamos ya en esta pantalla
            if (ModalRoute.of(context)?.settings.name != scrollScreenRoute) {
              Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
            }
            break;
          case 1:
            // Garaje
            // Solo navega si no estamos ya en esta pantalla
            if (ModalRoute.of(context)?.settings.name != buscarScreenRoute) {
              Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
            }
            break;
          case 2:
            // Buscar
            // Solo navega si no estamos ya en esta pantalla
            if (ModalRoute.of(context)?.settings.name != garageScreenRoute) {
              Navigator.of(context).pushReplacementNamed(garageScreenRoute);
            }
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),//Icono de inicio
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search), // Icono de garaje
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warehouse), // Icono de lupita 
          label: 'Garage',
        ),
      ],
    );
  }
}