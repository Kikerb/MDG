import 'package:flutter/material.dart';

class CompartirInputScreen extends StatefulWidget {
  final String? textoInicial;

  const CompartirInputScreen({Key? key, this.textoInicial}) : super(key: key);

  @override
  State<CompartirInputScreen> createState() => _CompartirInputScreenState();
}

class _CompartirInputScreenState extends State<CompartirInputScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textoInicial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _contenidoValido => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir contenido'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Cierra sin resultado
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe lo que quieres compartir...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Para actualizar el botón cuando cambie el texto
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _contenidoValido
                  ? () {
                      Navigator.pop(context, _controller.text.trim());
                    }
                  : null,
              icon: const Icon(Icons.send),
              label: const Text('Compartir'),
            )
          ],
        ),
      ),
    );
  }
}
