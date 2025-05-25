import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // Asegúrate de que la ruta sea correcta

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Obtener la referencia a la colección de usuarios
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// ----------------------------------------------------------
  /// Métodos de Creación y Recuperación de Perfil
  /// ----------------------------------------------------------

  /// Crea un nuevo perfil de usuario en Firestore al registrarse.
  /// Asume que el usuario ya está autenticado en Firebase Auth.
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
  }) async {
    try {
      final newUser = UserModel(
        uid: uid,
        email: email,
        username: username,
        createdAt: Timestamp.now(),
        lastActive: Timestamp.now(),
        followersCount: 0,
        followingCount: 0,
        garageSlots: 5, // Valor por defecto inicial
        garageSlotsUsed: 0,
        isPremiumUser: false,
        interests: [],
        profileImageUrl: null, // Inicialmente sin imagen de perfil
      );
      await _usersCollection.doc(uid).set(newUser.toFirestore());
      print('Perfil de usuario $uid creado con éxito.');
    } catch (e) {
      print('Error al crear el perfil de usuario $uid: $e');
      rethrow; // Relanza la excepción para que pueda ser manejada por la UI
    }
  }

  /// Obtiene un stream de UserModel para un UID dado.
  /// Ideal para escuchar cambios en tiempo real del perfil del usuario.
  Stream<UserModel> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Podrías lanzar un error o devolver un modelo predeterminado si el documento no existe
        throw Exception('Usuario con UID $uid no encontrado.');
      }
    });
  }

  /// Obtiene los datos de UserModel una única vez para un UID dado.
  Future<UserModel?> getUserOnce(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener el usuario $uid: $e');
      return null;
    }
  }

  /// ----------------------------------------------------------
  /// Métodos de Actualización de Perfil
  /// ----------------------------------------------------------

  /// Actualiza cualquier campo del perfil del usuario.
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      print('Datos del usuario $uid actualizados con éxito.');
    } catch (e) {
      print('Error al actualizar los datos del usuario $uid: $e');
      rethrow;
    }
  }

  /// Actualiza la URL de la imagen de perfil de un usuario.
  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    return updateUserData(uid, {'profileImageUrl': imageUrl});
  }

  /// Actualiza la última fecha de actividad del usuario.
  Future<void> updateLastActive(String uid) async {
    return updateUserData(uid, {'lastActive': Timestamp.now()});
  }

  /// ----------------------------------------------------------
  /// Métodos de Seguidores/Siguiendo
  /// ----------------------------------------------------------

  /// Sigue a un usuario.
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // 1. Añadir targetUserId a la lista 'following' del usuario actual
      await _usersCollection.doc(currentUserId).update({
        'following': FieldValue.arrayUnion([targetUserId]),
        'followingCount': FieldValue.increment(1),
      });

      // 2. Añadir currentUserId a la lista 'followers' del usuario objetivo
      await _usersCollection.doc(targetUserId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
        'followersCount': FieldValue.increment(1),
      });
      print('$currentUserId ahora sigue a $targetUserId');
    } catch (e) {
      print('Error al seguir usuario $targetUserId: $e');
      rethrow;
    }
  }

  /// Deja de seguir a un usuario.
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // 1. Remover targetUserId de la lista 'following' del usuario actual
      await _usersCollection.doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      // 2. Remover currentUserId de la lista 'followers' del usuario objetivo
      await _usersCollection.doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followersCount': FieldValue.increment(-1),
      });
      print('$currentUserId ha dejado de seguir a $targetUserId');
    } catch (e) {
      print('Error al dejar de seguir usuario $targetUserId: $e');
      rethrow;
    }
  }

  /// Verifica si el usuario actual ya sigue a otro usuario.
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final currentUserDoc = await _usersCollection.doc(currentUserId).get();
      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data();
        if (userData != null && userData.containsKey('following')) {
          final List<dynamic> following = userData['following'];
          return following.contains(targetUserId);
        }
      }
      return false;
    } catch (e) {
      print('Error al verificar si sigue al usuario: $e');
      return false;
    }
  }


  /// ----------------------------------------------------------
  /// Métodos de Plazas de Garaje
  /// ----------------------------------------------------------

  /// Incrementa las plazas de garaje usadas.
  Future<void> incrementGarageSlotsUsed(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'garageSlotsUsed': FieldValue.increment(1),
      });
      print('Plazas de garaje usadas incrementadas para $userId.');
    } catch (e) {
      print('Error al incrementar plazas de garaje: $e');
      rethrow;
    }
  }

  /// Decrementa las plazas de garaje usadas.
  Future<void> decrementGarageSlotsUsed(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'garageSlotsUsed': FieldValue.increment(-1),
      });
      print('Plazas de garaje usadas decrementadas para $userId.');
    } catch (e) {
      print('Error al decrementar plazas de garaje: $e');
      rethrow;
    }
  }

  /// Actualiza el total de plazas de garaje del usuario (ej. por suscripción premium).
  Future<void> updateGarageSlots(String userId, int newTotalSlots) async {
    try {
      await _usersCollection.doc(userId).update({
        'garageSlots': newTotalSlots,
      });
      print('Total de plazas de garaje actualizado para $userId.');
    } catch (e) {
      print('Error al actualizar total de plazas de garaje: $e');
      rethrow;
    }
  }

  /// ----------------------------------------------------------
  /// Otros Métodos (Ej. Premium, Intereses)
  /// ----------------------------------------------------------

  /// Cambia el estado premium de un usuario.
  Future<void> setPremiumStatus(String userId, bool isPremium) async {
    try {
      await _usersCollection.doc(userId).update({
        'isPremiumUser': isPremium,
      });
      print('Estado premium de $userId actualizado a $isPremium.');
    } catch (e) {
      print('Error al actualizar estado premium: $e');
      rethrow;
    }
  }

  /// Actualiza los intereses de un usuario.
  Future<void> updateInterests(String userId, List<String> interests) async {
    try {
      await _usersCollection.doc(userId).update({
        'interests': interests,
      });
      print('Intereses de $userId actualizados.');
    } catch (e) {
      print('Error al actualizar intereses: $e');
      rethrow;
    }
  }
}