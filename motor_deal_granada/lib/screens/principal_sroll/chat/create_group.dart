import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  File? _groupImage;
  final ImagePicker _picker = ImagePicker();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<String> _selectedParticipants = []; // UIDs de los participantes seleccionados
  List<Map<String, dynamic>> _availableUsers = []; // Lista de usuarios disponibles para añadir

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // El creador siempre es participante. Asegúrate de añadirlo solo si no está ya.
    if (currentUser != null && !_selectedParticipants.contains(currentUser!.uid)) {
      _selectedParticipants.add(currentUser!.uid);
    }
    _fetchAvailableUsers();
  }

  Future<void> _fetchAvailableUsers() async {
    if (currentUser == null) return;

    setState(() {
      _isLoading = true; // Inicia la carga
    });

    try {
      QuerySnapshot allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        _availableUsers = allUsersSnapshot.docs
            .map((doc) {
              // Acceder a los datos de forma segura usando .data()?
              final data = doc.data() as Map<String, dynamic>?;

              // Si el documento no tiene datos o es nulo, retornar un mapa con valores por defecto
              if (data == null) {
                return {
                  'uid': doc.id,
                  'username': 'Usuario',
                  'email': '',
                  'profileImageUrl': 'https://i.imgur.com/BoN9kdC.png',
                };
              }

              return {
                  'uid': doc.id,
                  // Acceso seguro a 'username' y 'email'
                  'username': data['username'] ?? data['email'] ?? 'Usuario',
                  'email': data['email'] ?? '',
                  'profileImageUrl': data['profileImageUrl'] ?? 'https://i.imgur.com/BoN9kdC.png',
              };
            })
            .where((user) => user['uid'] != currentUser!.uid) // Filtra al usuario actual
            .toList();
      });

    } catch (e) {
      print('Error al cargar usuarios disponibles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickGroupImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadGroupImage(String groupId) async {
    if (_groupImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('group_images').child('$groupId.jpg');
      await storageRef.putFile(_groupImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen del grupo: $e');
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedParticipants.length < 2) { // Un grupo necesita al menos 2 personas (el creador + 1 más)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un grupo debe tener al menos 2 participantes.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final groupRef = FirebaseFirestore.instance.collection('groups').doc(); // Genera un ID automático
        final groupId = groupRef.id;

        String? groupImageUrl;
        if (_groupImage != null) {
          groupImageUrl = await _uploadGroupImage(groupId);
        }

        await groupRef.set({
          'groupId': groupId,
          'name': _groupNameController.text.trim(),
          'imageUrl': groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png', // Imagen por defecto
          'participants': _selectedParticipants,
          'adminId': currentUser!.uid, // El creador es el primer administrador
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageContent': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });

        // Opcional: Crear un documento de chat inicial para el grupo en 'messages'
        // Esto es similar a cómo manejas los chats individuales, pero 'isGroupChat' será true
        await FirebaseFirestore.instance.collection('messages').doc(groupId).set({
          'chatId': groupId, // El chatId es el mismo que el groupId
          'isGroupChat': true,
          'participants': _selectedParticipants,
          'lastMessageContent': 'Grupo creado.',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSenderId': currentUser!.uid,
          'groupName': _groupNameController.text.trim(),
          'groupImageUrl': groupImageUrl ?? 'https://i.imgur.com/BoN9kdC.png',
          'unreadCounts': { for (var uid in _selectedParticipants) uid : 0 }, // Inicializa todos en 0
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo creado exitosamente!')),
        );
        Navigator.pop(context); // Vuelve a la pantalla de la lista de chats

      } catch (e) {
        print('Error al crear grupo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear grupo: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Crear Nuevo Grupo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickGroupImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _groupImage != null ? FileImage(_groupImage!) : null,
                          child: _groupImage == null
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Grupo',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, introduce un nombre para el grupo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Participantes Seleccionados:',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Lista de participantes seleccionados (incluyendo el actual)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedParticipants.map((uid) {
                        final user = _availableUsers.firstWhereOrNull((u) => u['uid'] == uid);

                        String displayName = 'Cargando...';
                        String displayImageUrl = 'https://i.imgur.com/BoN9kdC.png'; // Imagen por defecto

                        if (user != null) {
                          // Priorizar el email si el username no está disponible
                          displayName = user['email'] ?? user['username'] ?? 'Usuario';
                          displayImageUrl = user['profileImageUrl'];
                        } else if (uid == currentUser!.uid) {
                          displayName = 'Tú';
                          // Opcional: Si quieres mostrar tu propio email aquí en vez de "Tú", puedes usar:
                          // displayName = currentUser!.email ?? 'Tú';
                        }

                        return Chip(
                          avatar: CircleAvatar(backgroundImage: NetworkImage(displayImageUrl)),
                          label: Text(
                            displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blueGrey,
                          deleteIcon: uid != currentUser!.uid ? const Icon(Icons.close, size: 18, color: Colors.white70) : null,
                          onDeleted: uid != currentUser!.uid
                              ? () {
                                  setState(() {
                                    _selectedParticipants.remove(uid);
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Añadir Participantes:',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _availableUsers.isEmpty && !_isLoading
                        ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No hay usuarios disponibles para añadir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                        : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availableUsers.length,
                              itemBuilder: (context, index) {
                                final user = _availableUsers[index];
                                final bool isSelected = _selectedParticipants.contains(user['uid']);

                                return Card(
                                  color: Colors.grey[900],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: CheckboxListTile(
                                    tileColor: isSelected ? Colors.grey[700] : Colors.grey[900],
                                    checkColor: Colors.white,
                                    activeColor: Colors.purpleAccent,
                                    title: Text(
                                      // Mostrar el email como título
                                      user['email'] ?? user['username'] ?? 'Usuario',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      // El username puede ir en el subtítulo si lo deseas
                                      user['username'] ?? '',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundImage: NetworkImage(user['profileImageUrl']),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedParticipants.add(user['uid']);
                                        } else {
                                          _selectedParticipants.remove(user['uid']);
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _createGroup,
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        label: const Text(
                          'Crear Grupo',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Extensión para List para simular .firstWhereOrNull
// Flutter 3.10+ ya lo tiene, pero si usas una versión anterior, esto es útil.
extension CreateGroupListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}