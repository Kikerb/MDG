import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // ID único del usuario (Document ID en Firestore, coincide con Firebase Auth UID)
  final String email;
  final String username; // Ahora es requerido (no opcional), ya que es un campo clave
  final String? profileImageUrl; // URL de la imagen de perfil, puede ser null
  final Timestamp createdAt; // Marca de tiempo de creación de la cuenta
  final int followersCount; // Cantidad de usuarios que siguen a este
  final int followingCount; // Cantidad de usuarios que este usuario sigue
  final int garageSlots; // Cantidad total de plazas de garaje que tiene el usuario
  final int garageSlotsUsed; // Cantidad de plazas de garaje actualmente en uso
  final bool isPremiumUser; // Indica si el usuario tiene una suscripción premium
  final Timestamp lastActive; // Última vez que el usuario estuvo activo
  final List<String> interests; // Intereses del usuario para personalización del feed
  final String? bio; // ¡Campo nuevo añadido!

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    required this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.garageSlots = 5, // Por defecto, 5 plazas
    this.garageSlotsUsed = 0,
    this.isPremiumUser = false,
    required this.lastActive,
    this.interests = const [],
    this.bio, // ¡Añadido al constructor!
  });

  // Factory constructor para crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '', // Asegúrate de que el email siempre esté presente
      username: data['username'] ?? 'Usuario Anónimo', // Valor por defecto si no existe
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(), // Por defecto, la hora actual si no existe
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      garageSlots: data['garageSlots'] ?? 5, // Por defecto 5 si no se especifica
      garageSlotsUsed: data['garageSlotsUsed'] ?? 0,
      isPremiumUser: data['isPremiumUser'] ?? false,
      lastActive: data['lastActive'] ?? Timestamp.now(), // Por defecto, la hora actual si no existe
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'] as String?, // ¡Lectura del campo 'bio'!
    );
  }

  // Método para convertir un UserModel a un Map, útil para subir/actualizar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'garageSlots': garageSlots,
      'garageSlotsUsed': garageSlotsUsed,
      'isPremiumUser': isPremiumUser,
      'lastActive': lastActive,
      'interests': interests,
      'bio': bio, // ¡Escritura del campo 'bio'!
    };
  }

  // Método copyWith para crear una copia modificada de un UserModel (útil para actualizaciones inmutables)
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    Timestamp? createdAt,
    int? followersCount,
    int? followingCount,
    int? garageSlots,
    int? garageSlotsUsed,
    bool? isPremiumUser,
    Timestamp? lastActive,
    List<String>? interests,
    String? bio, // ¡Añadido al copyWith!
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      garageSlots: garageSlots ?? this.garageSlots,
      garageSlotsUsed: garageSlotsUsed ?? this.garageSlotsUsed,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      lastActive: lastActive ?? this.lastActive,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio, // ¡Asignación del bio en copyWith!
    );
  }
}