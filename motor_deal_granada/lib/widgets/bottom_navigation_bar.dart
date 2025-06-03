import 'package:flutter/material.dart';
import '../main.dart'; // Importa main.dart para las rutas

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              offset: Offset(0, -2),
              blurRadius: 12,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.white70,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            onItemSelected(index);

            switch (index) {
              case 0:
                if (ModalRoute.of(context)?.settings.name != scrollScreenRoute) {
                  Navigator.of(context).pushReplacementNamed(scrollScreenRoute);
                }
                break;
              case 1:
                if (ModalRoute.of(context)?.settings.name != buscarScreenRoute) {
                  Navigator.of(context).pushReplacementNamed(buscarScreenRoute);
                }
                break;
              case 2:
                if (ModalRoute.of(context)?.settings.name != addPostScreenRoute) {
                  Navigator.of(context).pushReplacementNamed(addPostScreenRoute);
                }
                break;
              case 3:
                if (ModalRoute.of(context)?.settings.name != cartScreenRoute) {
                  Navigator.of(context).pushReplacementNamed(cartScreenRoute);
                }
                break;
              case 4:
                if (ModalRoute.of(context)?.settings.name != garageScreenRoute) {
                  Navigator.of(context).pushReplacementNamed(garageScreenRoute);
                }
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
              icon: Icon(Icons.add_circle),
              label: 'Publicar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Carrito',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse),
              label: 'Garaje',
            ),
          ],
        ),
      ),
    );
  }
}
