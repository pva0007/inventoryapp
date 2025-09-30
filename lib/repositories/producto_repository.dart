import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/producto.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CategoriaRepository _categoriaRepo = CategoriaRepository();

  Future<void> addProducto(Producto producto) async {
    // Determine target collection path based on category
    if (producto.categoryId != null && producto.categoryId!.isNotEmpty) {
      final categoria = await _categoriaRepo.getCategoriaById(
        producto.categoryId!,
      );
      if (categoria != null) {
        if (categoria.parentId != null && categoria.parentId!.isNotEmpty) {
          // collections/{parentId}/categorias/{categoryId}/productos
          await _firestore
              .collection('collections')
              .doc(categoria.parentId)
              .collection('categorias')
              .doc(categoria.id)
              .collection('productos')
              .add(producto.toMap());
          return;
        } else {
          // parent category stored under 'collections'
          await _firestore
              .collection('collections')
              .doc(categoria.id)
              .collection('productos')
              .add(producto.toMap());
          return;
        }
      }
    }

    // Fallback to top-level 'productos'
    await _firestore.collection('productos').add(producto.toMap());
  }

  /// Uploads a file to Firebase Storage under 'product_images/<filename>' and
  /// returns the download URL.
  Future<String> uploadProductImage(File file, String filename) async {
    final ref = _storage.ref().child('product_images').child(filename);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> updateProducto(Producto producto) async {
    // Try to update in nested path based on producto.categoryId
    if (producto.categoryId != null && producto.categoryId!.isNotEmpty) {
      final categoria = await _categoriaRepo.getCategoriaById(
        producto.categoryId!,
      );
      if (categoria != null) {
        if (categoria.parentId != null && categoria.parentId!.isNotEmpty) {
          await _firestore
              .collection('collections')
              .doc(categoria.parentId)
              .collection('categorias')
              .doc(categoria.id)
              .collection('productos')
              .doc(producto.id)
              .update(producto.toMap());
          return;
        } else {
          await _firestore
              .collection('collections')
              .doc(categoria.id)
              .collection('productos')
              .doc(producto.id)
              .update(producto.toMap());
          return;
        }
      }
    }

    // Fallback: try top-level
    await _firestore
        .collection('productos')
        .doc(producto.id)
        .update(producto.toMap());
  }

  Future<void> deleteProducto(String id) async {
    // Deleting without knowing path: try top-level first, then attempt to find under known category paths.
    try {
      await _firestore.collection('productos').doc(id).delete();
      return;
    } catch (_) {}

    // As a best-effort, iterate categories and attempt delete at each possible subcollection path.
    final cats = await _categoriaRepo.getCategorias().first;
    for (final c in cats) {
      try {
        if (c.parentId != null && c.parentId!.isNotEmpty) {
          await _firestore
              .collection('collections')
              .doc(c.parentId)
              .collection('categorias')
              .doc(c.id)
              .collection('productos')
              .doc(id)
              .delete();
        } else {
          await _firestore
              .collection('collections')
              .doc(c.id)
              .collection('productos')
              .doc(id)
              .delete();
        }
      } catch (_) {
        // ignore and continue
      }
    }
  }

  /* Stream<List<Producto>> getProductos() {
    return _firestore.collection('productos').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Producto.fromMap(doc.id, doc.data()))
          .toList();
    });*/
  Stream<List<Producto>> getProductos() {
    final controller = StreamController<List<Producto>>.broadcast();

    List<Producto> topLevel = [];
    final Map<String, List<Producto>> subResults = {};

    StreamSubscription? topSub;
    StreamSubscription? catsSub;
    final List<StreamSubscription> subSubs = [];

    void emit() {
      final combined = <Producto>[];
      combined.addAll(topLevel);
      for (final list in subResults.values) {
        combined.addAll(list);
      }
      controller.add(combined);
    }

    topSub = _firestore.collection('productos').snapshots().listen((snap) {
      topLevel = snap.docs
          .map(
            (d) => Producto.fromMap(
              d.id,
              Map<String, dynamic>.from(d.data() as Map),
            ),
          )
          .toList();
      emit();
    }, onError: (e) => controller.addError(e));

    // Listen to categories and subscribe to their product subcollections
    catsSub = _categoriaRepo.getCategorias().listen((cats) {
      // cancel previous subs
      for (final s in subSubs) {
        s.cancel();
      }
      subSubs.clear();
      subResults.clear();

      for (final c in cats) {
        CollectionReference prodColl;
        if (c.parentId != null && c.parentId!.isNotEmpty) {
          prodColl = _firestore
              .collection('collections')
              .doc(c.parentId)
              .collection('categorias')
              .doc(c.id)
              .collection('productos');
        } else {
          prodColl = _firestore
              .collection('collections')
              .doc(c.id)
              .collection('productos');
        }

        final sub = prodColl.snapshots().listen((snap) {
          subResults[c.id] = snap.docs
              .map(
                (d) => Producto.fromMap(
                  d.id,
                  Map<String, dynamic>.from(d.data() as Map),
                ),
              )
              .toList();
          emit();
        }, onError: (e) => controller.addError(e));

        subSubs.add(sub);
      }
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () async {
      await topSub?.cancel();
      await catsSub?.cancel();
      for (final s in subSubs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  Stream<List<Producto>> getProductosPorCategoria(String categoryId) {
    // Determine category and subscribe to its specific products subcollection
    final controller = StreamController<List<Producto>>.broadcast();

    (() async {
      try {
        final categoria = await _categoriaRepo.getCategoriaById(categoryId);
        if (categoria == null) {
          // fallback to top-level filtered query
          final sub = _firestore
              .collection('productos')
              .where('categoryId', isEqualTo: categoryId)
              .snapshots()
              .listen(
                (snap) => controller.add(
                  snap.docs
                      .map(
                        (d) => Producto.fromMap(
                          d.id,
                          Map<String, dynamic>.from(d.data() as Map),
                        ),
                      )
                      .toList(),
                ),
                onError: (e) => controller.addError(e),
              );
          controller.onCancel = () => sub.cancel();
        } else {
          CollectionReference prodColl;
          if (categoria.parentId != null && categoria.parentId!.isNotEmpty) {
            prodColl = _firestore
                .collection('collections')
                .doc(categoria.parentId)
                .collection('categorias')
                .doc(categoria.id)
                .collection('productos');
          } else {
            prodColl = _firestore
                .collection('collections')
                .doc(categoria.id)
                .collection('productos');
          }

          final sub = prodColl.snapshots().listen((snap) {
            controller.add(
              snap.docs
                  .map(
                    (d) => Producto.fromMap(
                      d.id,
                      Map<String, dynamic>.from(d.data() as Map),
                    ),
                  )
                  .toList(),
            );
          }, onError: (e) => controller.addError(e));

          controller.onCancel = () => sub.cancel();
        }
      } catch (e) {
        controller.addError(e);
      }
    })();

    return controller.stream;
  }

  Stream<List<Producto>> getProductosPorTag(String tag) {
    // Aggregate results from top-level and nested product subcollections
    final controller = StreamController<List<Producto>>.broadcast();
    List<Producto> top = [];
    final Map<String, List<Producto>> subs = {};
    StreamSubscription? topSub;
    StreamSubscription? catsSub;
    final List<StreamSubscription> subSubs = [];

    void emit() {
      final combined = <Producto>[];
      combined.addAll(top);
      for (final s in subs.values) combined.addAll(s);
      controller.add(
        combined.where((p) => p.tags != null && p.tags!.contains(tag)).toList(),
      );
    }

    topSub = _firestore
        .collection('productos')
        .where('tags', arrayContains: tag)
        .snapshots()
        .listen((snap) {
          top = snap.docs.map((d) => Producto.fromMap(d.id, d.data())).toList();
          emit();
        }, onError: (e) => controller.addError(e));

    catsSub = _categoriaRepo.getCategorias().listen((cats) {
      for (final s in subSubs) s.cancel();
      subSubs.clear();
      subs.clear();
      for (final c in cats) {
        CollectionReference prodColl;
        if (c.parentId != null && c.parentId!.isNotEmpty) {
          prodColl = _firestore
              .collection('collections')
              .doc(c.parentId)
              .collection('categorias')
              .doc(c.id)
              .collection('productos');
        } else {
          prodColl = _firestore
              .collection('collections')
              .doc(c.id)
              .collection('productos');
        }
        final sub = prodColl
            .where('tags', arrayContains: tag)
            .snapshots()
            .listen((snap) {
              subs[c.id] = snap.docs
                  .map(
                    (d) => Producto.fromMap(
                      d.id,
                      Map<String, dynamic>.from(d.data() as Map),
                    ),
                  )
                  .toList();
              emit();
            }, onError: (e) => controller.addError(e));
        subSubs.add(sub);
      }
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () async {
      await topSub?.cancel();
      await catsSub?.cancel();
      for (final s in subSubs) await s.cancel();
    };

    return controller.stream;
  }
}
