import 'package:cloud_firestore/cloud_firestore.dart';

class OfficialProductModel {
  final String id; // ID del documento (auto-generado por Firestore)
  final String productName; // Nombre del producto, ej., "Kit de Frenos Brembo"
  final String productType; // Tipo de producto: "Pieza Nueva", "Vehículo Certificado"
  final String description; // Descripción detallada del producto
  final double price; // Precio del producto
  final String currency; // Moneda, ej., "EUR", "USD"
  final List<String> images; // URLs de las imágenes del producto
  final int stock; // Cantidad disponible en stock
  final String? warrantyInfo; // Información de garantía, opcional
  final Timestamp listedAt; // Fecha y hora en que se listó el producto
  final Timestamp lastUpdated; // Última fecha de actualización del producto
  final bool isAvailable; // Indica si el producto está disponible para la venta

  OfficialProductModel({
    required this.id,
    required this.productName,
    required this.productType,
    required this.description,
    required this.price,
    required this.currency,
    this.images = const [],
    required this.stock,
    this.warrantyInfo,
    required this.listedAt,
    required this.lastUpdated,
    this.isAvailable = true, // Por defecto, disponible al listar
  });

  // Factory constructor para crear un OfficialProductModel desde un DocumentSnapshot de Firestore
  factory OfficialProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OfficialProductModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      productType: data['productType'] ?? 'General', // Valor por defecto
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0, // Casteo seguro a double
      currency: data['currency'] ?? 'EUR', // Valor por defecto
      images: List<String>.from(data['images'] ?? []),
      stock: data['stock'] ?? 0,
      warrantyInfo: data['warrantyInfo'],
      listedAt: data['listedAt'] ?? Timestamp.now(),
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Método para convertir un OfficialProductModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'productType': productType,
      'description': description,
      'price': price,
      'currency': currency,
      'images': images,
      'stock': stock,
      'warrantyInfo': warrantyInfo,
      'listedAt': listedAt,
      'lastUpdated': lastUpdated,
      'isAvailable': isAvailable,
    };
  }

  // Método copyWith para crear una copia modificada de un OfficialProductModel (útil para actualizaciones inmutables)
  OfficialProductModel copyWith({
    String? id,
    String? productName,
    String? productType,
    String? description,
    double? price,
    String? currency,
    List<String>? images,
    int? stock,
    String? warrantyInfo,
    Timestamp? listedAt,
    Timestamp? lastUpdated,
    bool? isAvailable,
  }) {
    return OfficialProductModel(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      warrantyInfo: warrantyInfo ?? this.warrantyInfo,
      listedAt: listedAt ?? this.listedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}