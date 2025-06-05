import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/part_model.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../repository/part_repository.dart';
import 'create_part_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _currentIndex = 3;
  final PartRepository _partRepository = PartRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Mercado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A0033), Color.fromARGB(255, 60, 0, 100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PartModel>>(
        stream: _partRepository.fetchAvailablePartsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los productos',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final parts = snapshot.data ?? [];
          if (parts.isEmpty) {
            return const Center(
              child: Text('No hay piezas disponibles aún.',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: parts.length,
            itemBuilder: (context, index) {
              final part = parts[index];
              return Card(
                color: const Color(0xFF1A0033),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: part.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: part.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[700],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.white54),
                          ),
                  ),
                  title: Text(
                    part.partName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${part.price.toStringAsFixed(2)} ${part.currency} - ${part.condition}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white30, size: 16),
                  onTap: () {
                    // Aquí podrías abrir una pantalla de detalles si lo deseas
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePartScreen()),
          );

          if (result == true) {
            setState(() {}); // reconstruye la UI si se añadió una pieza
          }
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
