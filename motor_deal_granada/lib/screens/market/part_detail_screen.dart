import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/part_model.dart';
import 'CheckoutScreen.dart';

class PartDetailScreen extends StatelessWidget {
  final PartModel part;

  const PartDetailScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Detalle de la Pieza',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: part.imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              part.partName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${part.price.toStringAsFixed(2)} ${part.currency}',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Total con comisión: ${part.getTotalWithCommission(10).toStringAsFixed(2)} ${part.currency}',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
            ),
            Text(
              'Estado: ${part.condition}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Descripción',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              part.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (part.vehicleCompatibility.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compatibilidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...part.vehicleCompatibility.map(
                    (model) => Text(
                      '- $model',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckoutScreen(part: part)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Comprar ahora'),
        ),
      ),
    );
  }
}
