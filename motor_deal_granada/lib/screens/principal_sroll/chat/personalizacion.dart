import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizacionScreen extends StatefulWidget {
  const PersonalizacionScreen({super.key});

  @override
  State<PersonalizacionScreen> createState() => _PersonalizacionScreenState();
}

class _PersonalizacionScreenState extends State<PersonalizacionScreen> {
  late SharedPreferences prefs;

  Color chatBackground = Colors.black;
  Color myMessageColor = Colors.purple;
  Color otherMessageColor = Colors.grey[800]!;
  double fontSize = 14;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      chatBackground = Color(prefs.getInt('chatBackground') ?? Colors.black.value);
      myMessageColor = Color(prefs.getInt('myMessageColor') ?? Colors.purple.value);
      otherMessageColor = Color(prefs.getInt('otherMessageColor') ?? Colors.grey[800]!.value);
      fontSize = prefs.getDouble('fontSize') ?? 14;
    });
  }

  Future<void> _savePrefs() async {
    await prefs.setInt('chatBackground', chatBackground.value);
    await prefs.setInt('myMessageColor', myMessageColor.value);
    await prefs.setInt('otherMessageColor', otherMessageColor.value);
    await prefs.setDouble('fontSize', fontSize);

    if (context.mounted) {
      Navigator.pop(context, true); // <- Esto notifica al ChatScreen que debe recargar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferencias guardadas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalización del Chat"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePrefs,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Color de fondo del chat", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _colorSelector((c) => chatBackground = c, chatBackground),
          const Divider(),

          const Text("Color de tus mensajes", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _colorSelector((c) => myMessageColor = c, myMessageColor),
          const Divider(),

          const Text("Color de mensajes del otro usuario", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _colorSelector((c) => otherMessageColor = c, otherMessageColor),
          const Divider(),

          const Text("Tamaño del texto", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 12,
            max: 24,
            divisions: 6,
            label: fontSize.toInt().toString(),
            value: fontSize,
            onChanged: (value) => setState(() => fontSize = value),
          ),
        ],
      ),
    );
  }

  Widget _colorSelector(Function(Color) onSelect, Color current) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.deepPurple,
      Colors.blueGrey,
      Colors.teal,
      Colors.redAccent,
      Colors.green,
      Colors.brown,
    ];

    return Wrap(
      spacing: 10,
      children: colors.map((color) {
        final isSelected = color.value == current.value;
        return GestureDetector(
          onTap: () => setState(() => onSelect(color)),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
            ),
          ),
        );
      }).toList(),
    );
  }
}
