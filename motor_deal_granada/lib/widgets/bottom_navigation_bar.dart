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
      backgroundColor: Colors.black, // Fondo de la barra negro
      selectedItemColor: Colors.purpleAccent, // Color del icono seleccionado (morado)
      unselectedItemColor: Colors.white, // Color del icono no seleccionado (blanco)
      currentIndex: currentIndex, // Usa el currentIndex pasado como parámetro
      onTap: (index) {
        // Ejecuta el callback proporcionado por el padre
        onItemSelected(index);

        // Lógica de navegación basada en el índice
        switch (index) {
          case 0:
            // Inicio
            if (ModalRoute.of(context)?.settings.name != scrollScreenRoute) {
              Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
            }
            break;
          case 1:
            // Buscar
            if (ModalRoute.of(context)?.settings.name != buscarScreenRoute) {
              Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
            }
            break;
          case 2:
            // Publicar (el nuevo botón central de 'más')
            // Asegúrate de que esta ruta esté definida en main.dart
            if (ModalRoute.of(context)?.settings.name != addPostScreenRoute) {
              Navigator.of(context).pushReplacementNamed(addPostScreenRoute);
            }
            break;
          case 3:
            // Carrito (el nuevo botón al lado de Garaje)
            // Asegúrate de que esta ruta esté definida en main.dart
            if (ModalRoute.of(context)?.settings.name != cartScreenRoute) {
              Navigator.of(context).pushReplacementNamed(cartScreenRoute);
            }
            break;
          case 4:
            // Garaje (ahora en la posición 4)
            if (ModalRoute.of(context)?.settings.name != garageScreenRoute) {
              Navigator.of(context).pushReplacementNamed(garageScreenRoute);
            }
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home), // Icono de inicio
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search), // Icono de buscar
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle), // Icono de añadir/publicar (el 'más' central)
          label: 'Publicar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart), // Icono de carrito
          label: 'Carrito',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warehouse), // Icono de garaje
          label: 'Garaje',
        ),
      ],
    );
  }
}
