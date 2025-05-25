import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id; // ID del documento (auto-generado por Firestore)
  final String userId; // UID del usuario que marcó el elemento como favorito
  final String itemId; // ID del elemento favorito (puede ser de 'posts', 'vehicles', 'parts', 'official_products')
  final String itemCollection; // La colección de origen del elemento: "posts", "vehicles", "parts", "official_products"
  final Timestamp favoritedAt; // Fecha y hora en que se marcó como favorito

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemCollection,
    required this.favoritedAt,
  });

  // Factory constructor para crear un FavoriteModel desde un DocumentSnapshot de Firestore
  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FavoriteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      itemId: data['itemId'] ?? '',
      itemCollection: data['itemCollection'] ?? '',
      favoritedAt: data['favoritedAt'] ?? Timestamp.now(),
    );
  }

  // Método para convertir un FavoriteModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'itemId': itemId,
      'itemCollection': itemCollection,
      'favoritedAt': favoritedAt,
    };
  }

  // Método copyWith para crear una copia modificada de un FavoriteModel (útil para actualizaciones inmutables)
  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? itemCollection,
    Timestamp? favoritedAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      itemCollection: itemCollection ?? this.itemCollection,
      favoritedAt: favoritedAt ?? this.favoritedAt,
    );
  }
}