import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id; // ID del documento (auto-generado por Firestore)
  final String userId; // UID del propietario del vehículo
  final String brand;
  final String model;
  final int year;
  final String description;
  final String mainImageUrl; // URL de la imagen principal del vehículo
  final Timestamp addedAt; // Fecha y hora en que se añadió el vehículo
  final String vehicleType; // Ej., "Coche", "Moto", "Furgoneta"
  final String currentStatus; // "En Venta", "Escucha Ofertas", "No en Venta"
  final double? price; // Precio (solo si currentStatus es "En Venta"), puede ser null
  final String? currency; // Ej., "EUR", "USD"
  final int mileage; // Kilometraje
  final String fuelType; // Ej., "Gasolina", "Diésel", "Eléctrico"
  final GeoPoint? location; // Ubicación geográfica del vehículo (opcional)
  final String? vin; // VIN (Número de Identificación del Vehículo), opcional y sensible
  final Timestamp lastModified; // Última fecha de modificación del vehículo
  final bool isActive; // Para activar/desactivar el vehículo en el garaje

  VehicleModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.description,
    required this.mainImageUrl,
    required this.addedAt,
    required this.vehicleType,
    required this.currentStatus,
    this.price,
    this.currency,
    required this.mileage,
    required this.fuelType,
    this.location,
    this.vin,
    required this.lastModified,
    this.isActive = true, // Por defecto activo al añadir
  });

  // Factory constructor para crear un VehicleModel desde un DocumentSnapshot de Firestore
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      description: data['description'] ?? '',
      mainImageUrl: data['mainImageUrl'] ?? '',
      addedAt: data['addedAt'] ?? Timestamp.now(),
      vehicleType: data['vehicleType'] ?? 'Coche',
      currentStatus: data['currentStatus'] ?? 'No en Venta',
      price: (data['price'] as num?)?.toDouble(), // Casteo seguro a double
      currency: data['currency'],
      mileage: data['mileage'] ?? 0,
      fuelType: data['fuelType'] ?? 'Desconocido',
      location: data['location'] as GeoPoint?,
      vin: data['vin'],
      lastModified: data['lastModified'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Método para convertir un VehicleModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'description': description,
      'mainImageUrl': mainImageUrl,
      'addedAt': addedAt,
      'vehicleType': vehicleType,
      'currentStatus': currentStatus,
      'price': price,
      'currency': currency,
      'mileage': mileage,
      'fuelType': fuelType,
      'location': location,
      'vin': vin,
      'lastModified': lastModified,
      'isActive': isActive,
    };
  }

  // Método copyWith para crear una copia modificada de un VehicleModel (útil para actualizaciones inmutables)
  VehicleModel copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    int? year,
    String? description,
    String? mainImageUrl,
    Timestamp? addedAt,
    String? vehicleType,
    String? currentStatus,
    double? price,
    String? currency,
    int? mileage,
    String? fuelType,
    GeoPoint? location,
    String? vin,
    Timestamp? lastModified,
    bool? isActive,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      description: description ?? this.description,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      addedAt: addedAt ?? this.addedAt,
      vehicleType: vehicleType ?? this.vehicleType,
      currentStatus: currentStatus ?? this.currentStatus,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      location: location ?? this.location,
      vin: vin ?? this.vin,
      lastModified: lastModified ?? this.lastModified,
      isActive: isActive ?? this.isActive,
    );
  }
}