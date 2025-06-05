import 'package:flutter/material.dart';
import '../../models/part_model.dart';

class CheckoutScreen extends StatelessWidget {
  final PartModel part;
  final double commissionPercentage = 10;

  const CheckoutScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final double commission = part.price * commissionPercentage / 100;
    final double total = part.getTotalWithCommission(commissionPercentage);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Resumen de Compra', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              part.partName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Precio base: ${part.price.toStringAsFixed(2)} ${part.currency}',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Comisión (${commissionPercentage.toInt()}%): ${commission.toStringAsFixed(2)} ${part.currency}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
            const Divider(height: 32, color: Colors.white24),
            Text('Total a pagar: $total ${part.currency}',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  // Aquí se implementaría el flujo de pago real
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compra realizada (simulada)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Regresar tras el "pago"
                },
                child: const Text('Pagar ahora', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
