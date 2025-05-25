import 'package:cloud_firestore/cloud_firestore.dart';

class PartModel {
  final String id; // ID del documento (auto-generado por Firestore)
  final String userId; // UID del vendedor de la pieza
  final String partName; // Nombre de la pieza, ej., "Turbo Garrett G25"
  final String description; // Descripción detallada de la pieza
  final double price; // Precio de la pieza
  final String currency; // Moneda, ej., "EUR", "USD"
  final String condition; // Estado de la pieza: "Nueva", "Usada", "Restaurada", "Para reparar"
  final String imageUrl; // URL de la imagen principal de la pieza
  final List<String> vehicleCompatibility; // Modelos o marcas de vehículos compatibles
  final GeoPoint? location; // Ubicación de la pieza (opcional)
  final Timestamp listedAt; // Fecha y hora en que se listó la pieza
  final bool isSold; // Indica si la pieza ya ha sido vendida

  PartModel({
    required this.id,
    required this.userId,
    required this.partName,
    required this.description,
    required this.price,
    required this.currency,
    required this.condition,
    required this.imageUrl,
    this.vehicleCompatibility = const [],
    this.location,
    required this.listedAt,
    this.isSold = false, // Por defecto, no vendida al listar
  });

  // Factory constructor para crear un PartModel desde un DocumentSnapshot de Firestore
  factory PartModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PartModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      partName: data['partName'] ?? 'Pieza Desconocida',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0, // Casteo seguro a double
      currency: data['currency'] ?? 'EUR', // Valor por defecto
      condition: data['condition'] ?? 'Usada', // Valor por defecto
      imageUrl: data['imageUrl'] ?? '',
      vehicleCompatibility: List<String>.from(data['vehicleCompatibility'] ?? []),
      location: data['location'] as GeoPoint?,
      listedAt: data['listedAt'] ?? Timestamp.now(),
      isSold: data['isSold'] ?? false,
    );
  }

  // Método para convertir un PartModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'partName': partName,
      'description': description,
      'price': price,
      'currency': currency,
      'condition': condition,
      'imageUrl': imageUrl,
      'vehicleCompatibility': vehicleCompatibility,
      'location': location,
      'listedAt': listedAt,
      'isSold': isSold,
    };
  }

  // Método copyWith para crear una copia modificada de un PartModel (útil para actualizaciones inmutables)
  PartModel copyWith({
    String? id,
    String? userId,
    String? partName,
    String? description,
    double? price,
    String? currency,
    String? condition,
    String? imageUrl,
    List<String>? vehicleCompatibility,
    GeoPoint? location,
    Timestamp? listedAt,
    bool? isSold,
  }) {
    return PartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partName: partName ?? this.partName,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      vehicleCompatibility: vehicleCompatibility ?? this.vehicleCompatibility,
      location: location ?? this.location,
      listedAt: listedAt ?? this.listedAt,
      isSold: isSold ?? this.isSold,
    );
  }
}