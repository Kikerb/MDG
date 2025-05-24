import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  _NoticiasScreenState createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  List noticias = [];

  @override
  void initState() {
    super.initState();
    fetchNoticias();
  }

  Future<void> fetchNoticias() async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=cars%20OR%20motorcycles&language=es&apiKey=64ad56b7cfff4be68b3f1ed3cc6a4439',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        noticias = data['articles'];
      });
    } else {
      print('Error al cargar noticias');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Noticias Coches y Motos'),
      ),
      body: noticias.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : ListView.builder(
              itemCount: noticias.length,
              itemBuilder: (context, index) {
                final noticia = noticias[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(noticia['title'] ?? '',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(noticia['description'] ?? '',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.open_in_new, color: Colors.purpleAccent),
                    onTap: () async {
                      final url = noticia['url'];
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
