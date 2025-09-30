import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a category. Parent categories (no parentId) are stored under
  /// top-level collection 'collections'. Subcategories (with parentId)
  /// are stored under 'categorias'. Returns the document id created/used.
  Future<String> addCategoria(Categoria categoria) async {
    if (categoria.parentId == null) {
      // parent category - store under 'collections'
      if (categoria.id.isEmpty) {
        final docRef = await _firestore
            .collection('collections')
            .add(categoria.toMap());
        return docRef.id;
      } else {
        await _firestore
            .collection('collections')
            .doc(categoria.id)
            .set(categoria.toMap());
        return categoria.id;
      }
    } else {
      // subcategory - store under 'categorias'
      if (categoria.id.isEmpty) {
        final docRef = await _firestore
            .collection('categorias')
            .add(categoria.toMap());
        return docRef.id;
      } else {
        await _firestore
            .collection('categorias')
            .doc(categoria.id)
            .set(categoria.toMap());
        return categoria.id;
      }
    }
  }

  Future<void> updateCategoria(Categoria categoria) async {
    // Try update in 'collections' first (parent), then 'categorias'
    final collRef = _firestore.collection('collections').doc(categoria.id);
    final collDoc = await collRef.get();
    if (collDoc.exists) {
      await collRef.update(categoria.toMap());
      return;
    }

    final catRef = _firestore.collection('categorias').doc(categoria.id);
    final catDoc = await catRef.get();
    if (catDoc.exists) {
      await catRef.update(categoria.toMap());
      return;
    }

    // If not found, throw
    throw Exception('Categoria with id ${categoria.id} not found');
  }

  Future<void> deleteCategoria(String id) async {
    // Try delete from 'collections' first, then 'categorias'
    final collRef = _firestore.collection('collections').doc(id);
    final collDoc = await collRef.get();
    if (collDoc.exists) {
      await collRef.delete();
      return;
    }

    final catRef = _firestore.collection('categorias').doc(id);
    final catDoc = await catRef.get();
    if (catDoc.exists) {
      await catRef.delete();
      return;
    }

    // Not found: do nothing or throw
    throw Exception('Categoria with id $id not found');
  }

  /// Returns a stream with combined list of parent categories (from
  /// 'collections') and subcategories (from 'categorias').
  Stream<List<Categoria>> getCategorias() {
    // We'll merge snapshots from both collections and emit combined lists.
    final controller = StreamController<List<Categoria>>.broadcast();

    List<Categoria> parents = [];
    List<Categoria> children = [];

    late StreamSubscription parentsSub;
    late StreamSubscription childrenSub;

    void emitCombined() {
      final combined = <Categoria>[];
      combined.addAll(parents);
      combined.addAll(children);
      controller.add(combined);
    }

    parentsSub = _firestore.collection('collections').snapshots().listen((
      snap,
    ) {
      parents = snap.docs
          .map((d) => Categoria.fromMap(d.id, d.data()))
          .toList();
      emitCombined();
    }, onError: (e) => controller.addError(e));

    childrenSub = _firestore.collection('categorias').snapshots().listen((
      snap,
    ) {
      children = snap.docs
          .map((d) => Categoria.fromMap(d.id, d.data()))
          .toList();
      emitCombined();
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () {
      parentsSub.cancel();
      childrenSub.cancel();
    };

    return controller.stream;
  }

  Future<Categoria?> getCategoriaById(String id) async {
    // Check in parents first
    final parentDoc = await _firestore.collection('collections').doc(id).get();
    if (parentDoc.exists)
      return Categoria.fromMap(parentDoc.id, parentDoc.data()!);

    final childDoc = await _firestore.collection('categorias').doc(id).get();
    if (childDoc.exists)
      return Categoria.fromMap(childDoc.id, childDoc.data()!);

    return null;
  }

  /// Stream of parent categories stored under 'collections'
  Stream<List<Categoria>> getParentCollections() {
    return _firestore.collection('collections').snapshots().map((snap) {
      return snap.docs.map((d) => Categoria.fromMap(d.id, d.data())).toList();
    });
  }
}
