import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../repositories/categoria_repository.dart';

class CategoriaProvider with ChangeNotifier {
  final CategoriaRepository _repository = CategoriaRepository();
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoriaProvider() {
    loadCategorias();
  }

  void loadCategorias() {
    _isLoading = true;
    notifyListeners();

    _repository.getCategorias().listen(
      (cats) {
        _categorias = cats;
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

  Future<String> addCategoria(Categoria categoria) async {
    try {
      final newId = await _repository.addCategoria(categoria);
      // reload categories to update local cache
      loadCategorias();
      return newId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategoria(Categoria categoria) async {
    try {
      await _repository.updateCategoria(categoria);
      loadCategorias();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategoria(String id) async {
    try {
      await _repository.deleteCategoria(id);
      loadCategorias();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
