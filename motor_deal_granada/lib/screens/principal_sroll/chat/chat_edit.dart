import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ChatThemeProvider with ChangeNotifier {
  Color _chatBubbleColor = Colors.purpleAccent;
  Color _chatOtherBubbleColor = Colors.grey[800]!;
  Color _chatTextColor = Colors.white;
  String _chatBackground = 'default';

  Color get chatBubbleColor => _chatBubbleColor;
  Color get chatOtherBubbleColor => _chatOtherBubbleColor;
  Color get chatTextColor => _chatTextColor;
  String get chatBackground => _chatBackground;

  ChatThemeProvider() {
    _loadChatPreferences();
  }

  void _loadChatPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _chatBubbleColor = Color(prefs.getInt('chatBubbleColor') ?? Colors.purpleAccent.value);
    _chatOtherBubbleColor = Color(prefs.getInt('chatOtherBubbleColor') ?? Colors.grey[800]!.value);
    _chatTextColor = Color(prefs.getInt('chatTextColor') ?? Colors.white.value);
    _chatBackground = prefs.getString('chatBackground') ?? 'default';
    notifyListeners();
  }

  void setChatBubbleColor(Color color) async {
    _chatBubbleColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatBubbleColor', color.value);
    notifyListeners();
  }

  void setChatOtherBubbleColor(Color color) async {
    _chatOtherBubbleColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatOtherBubbleColor', color.value);
    notifyListeners();
  }

  void setChatTextColor(Color color) async {
    _chatTextColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chatTextColor', color.value);
    notifyListeners();
  }

  void setChatBackground(String background) async {
    _chatBackground = background;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatBackground', background);
    notifyListeners();
  }
}

class ChatEditScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId;
  final String otherUserName;

  const ChatEditScreen({
    super.key,
    required this.chatId,
    this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatEditScreen> createState() => _ChatEditScreenState();
}

class _ChatEditScreenState extends State<ChatEditScreen> {
  final List<Color> availableBubbleColors = [
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.grey[700]!,
    Colors.pinkAccent,
  ];

  final List<Color> availableOtherBubbleColors = [
    Colors.grey[800]!,
    Colors.blueGrey[700]!,
    Colors.deepPurple[700]!,
    Colors.brown[700]!,
    Colors.indigo[700]!,
    Colors.lime[700]!,
  ];

  final List<Color> availableTextColors = [
    Colors.white,
    Colors.black,
    Colors.yellow,
    Colors.cyan,
  ];

  final List<Map<String, String>> availableBackgrounds = [
    {'name': 'Por defecto', 'value': 'default'},
    {'name': 'Degradado Azul', 'value': 'gradient_blue'},
    {'name': 'Degradado Verde', 'value': 'gradient_green'},
    {'name': 'Degradado Púrpura', 'value': 'gradient_purple'},
  ];

  @override
  Widget build(BuildContext context) {
    final chatThemeProvider = Provider.of<ChatThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Personalizar Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Color de tus burbujas'),
            _buildColorSelection(availableBubbleColors, chatThemeProvider.chatBubbleColor,
                chatThemeProvider.setChatBubbleColor),
            const SizedBox(height: 20),
            _buildSectionTitle('Color de las burbujas del otro'),
            _buildColorSelection(availableOtherBubbleColors, chatThemeProvider.chatOtherBubbleColor,
                chatThemeProvider.setChatOtherBubbleColor),
            const SizedBox(height: 20),
            _buildSectionTitle('Color del texto'),
            _buildColorSelection(availableTextColors, chatThemeProvider.chatTextColor,
                chatThemeProvider.setChatTextColor),
            const SizedBox(height: 20),
            _buildSectionTitle('Fondo del chat'),
            _buildBackgroundSelection(availableBackgrounds, chatThemeProvider.chatBackground,
                chatThemeProvider.setChatBackground),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuración guardada.')),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Guardar Configuración', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildColorSelection(List<Color> colors, Color selectedColor, Function(Color) onColorSelected) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedColor == color ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selectedColor == color
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundSelection(List<Map<String, String>> backgrounds, String selectedBackground,
      Function(String) onBackgroundSelected) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: backgrounds.length,
        itemBuilder: (context, index) {
          final background = backgrounds[index];
          final name = background['name']!;
          final value = background['value']!;

          Widget backgroundPreview;
          if (value.startsWith('gradient_')) {
            Gradient gradient;
            if (value == 'gradient_blue') {
              gradient = const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]);
            } else if (value == 'gradient_green') {
              gradient = const LinearGradient(colors: [Colors.green, Colors.lightGreenAccent]);
            } else if (value == 'gradient_purple') {
              gradient = const LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent]);
            } else {
              gradient = const LinearGradient(colors: [Colors.grey, Colors.black]);
            }
            backgroundPreview = Ink(
              decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            );
          } else {
            backgroundPreview = Container(
              color: Colors.grey[800],
              child: Center(
                child: Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onBackgroundSelected(value),
            child: Container(
              width: 80,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selectedBackground == value ? Colors.white : Colors.transparent, width: 3),
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: backgroundPreview),
            ),
          );
        },
      ),
    );
  }
}
