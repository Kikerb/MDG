import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id; // ID del documento (auto-generado por Firestore)
  final String userId; // UID del creador del post
  final String username; // Nombre de usuario del creador (desnormalizado)
  final String? profileImageUrl; // URL de la imagen de perfil del creador (desnormalizado, opcional)
  final String? vehicleId; // ID del vehículo asociado (de la colección 'vehicles'), null si no es un post de vehículo
  final String postType; // Tipo de post: "Vehículo", "Pieza", "General"
  final String imageUrl; // URL de la imagen principal del post
  final String description; // Descripción del post
  final Timestamp timestamp; // Marca de tiempo de la publicación
  final int likesCount; // Número de likes
  final int commentsCount; // Número de comentarios
  final int sharesCount; // Número de veces compartido
  final List<String> likedUserIds; // IDs de los usuarios a quienes les gusta esta publicación
  final List<String> tags; // Etiquetas para búsquedas y filtrado

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.vehicleId, // Es opcional ya que no todos los posts serán de vehículos
    required this.postType,
    required this.imageUrl,
    required this.description,
    required this.timestamp,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedUserIds = const [],
    this.tags = const [],
  });

  // Factory constructor para crear un PostModel desde un DocumentSnapshot de Firestore
  factory PostModel.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> data) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Usuario Desconocido',
      profileImageUrl: data['profileImageUrl'],
      vehicleId: data['vehicleId'],
      postType: data['postType'] ?? 'General', // Valor por defecto
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      likedUserIds: List<String>.from(data['likedUserIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Método para convertir un PostModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'vehicleId': vehicleId,
      'postType': postType,
      'imageUrl': imageUrl,
      'description': description,
      'timestamp': timestamp,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedUserIds': likedUserIds,
      'tags': tags,
    };
  }

  // Método copyWith para crear una copia modificada de un PostModel (útil para actualizaciones inmutables)
  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? profileImageUrl,
    String? vehicleId,
    String? postType,
    String? imageUrl,
    String? description,
    Timestamp? timestamp,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? likedUserIds,
    List<String>? tags,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      vehicleId: vehicleId ?? this.vehicleId,
      postType: postType ?? this.postType,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      tags: tags ?? this.tags,
    );
  }
}