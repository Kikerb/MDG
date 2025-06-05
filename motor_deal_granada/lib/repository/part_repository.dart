import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part_model.dart';

class PartRepository {
  final CollectionReference _partsCollection =
      FirebaseFirestore.instance.collection('parts');

  // Obtener todas las piezas (no vendidas)
  Future<List<PartModel>> fetchAvailableParts() async {
    final querySnapshot = await _partsCollection
        .where('isSold', isEqualTo: false)
        .orderBy('listedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PartModel.fromFirestore(doc))
        .toList();
  }

  // Obtener piezas por usuario (útil para ver inventario propio)
  Future<List<PartModel>> fetchPartsByUser(String userId) async {
    final querySnapshot = await _partsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('listedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => PartModel.fromFirestore(doc))
        .toList();
  }

  // Obtener una sola pieza por ID
  Future<PartModel?> getPartById(String id) async {
    final doc = await _partsCollection.doc(id).get();
    return doc.exists ? PartModel.fromFirestore(doc) : null;
  }

  // Crear una nueva pieza
  Future<void> addPart(PartModel part) async {
    await _partsCollection.doc(part.id).set(part.toFirestore());
  }

  // Actualizar una pieza existente
  Future<void> updatePart(PartModel part) async {
    await _partsCollection.doc(part.id).update(part.toFirestore());
  }

  // Marcar una pieza como vendida
  Future<void> markAsSold(String partId) async {
    await _partsCollection.doc(partId).update({'isSold': true});
  }

  // Eliminar una pieza
  Future<void> deletePart(String partId) async {
    await _partsCollection.doc(partId).delete();
  }
  Stream<List<PartModel>> fetchAvailablePartsStream() {
  return FirebaseFirestore.instance
      .collection('parts')
      .where('isSold', isEqualTo: false)
      .orderBy('listedAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PartModel.fromFirestore(doc)).toList());
}
}
