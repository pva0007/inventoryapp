import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../repositories/producto_repository.dart';

class ProductoProvider with ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();
  List<Producto> _productos = [];
  bool _isLoading = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Expose filtered streams for UI convenience
  Stream<List<Producto>> productosPorCategoria(String categoryId) {
    return _repository.getProductosPorCategoria(categoryId);
  }

  Stream<List<Producto>> productosPorTag(String tag) {
    return _repository.getProductosPorTag(tag);
  }

  ProductoProvider() {
    loadProductos();
  }

  void loadProductos() {
    _isLoading = true;
    notifyListeners();

    _repository.getProductos().listen(
      (productos) {
        _productos = productos;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addProducto(Producto producto) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.addProducto(producto);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProducto(Producto producto) async {
    await _repository.updateProducto(producto);
  }

  Future<void> deleteProducto(String id) async {
    await _repository.deleteProducto(id);
  }
}
