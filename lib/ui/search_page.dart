import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/producto_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/categoria.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productoProvider = Provider.of<ProductoProvider>(context);
    final categoriaProvider = Provider.of<CategoriaProvider>(context);

    final productos = productoProvider.productos;
    final categorias = categoriaProvider.categorias;

    final results = productos.where((p) {
      final q = _filter.toLowerCase();
      final inName = p.nombre.toLowerCase().contains(q);
      final inDesc = p.descripcion.toLowerCase().contains(q);
      final inCat =
          (p.categoryId != null &&
          categorias.any(
            (c) => c.id == p.categoryId && c.nombre.toLowerCase().contains(q),
          ));
      final inTags =
          p.tags != null && p.tags!.any((t) => t.toLowerCase().contains(q));
      return inName || inDesc || inCat || inTags;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _queryCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar productos o categorias',
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final p = results[index];
                  final catName = categorias
                      .firstWhere(
                        (c) => c.id == p.categoryId,
                        orElse: () => Categoria(id: '', nombre: ''),
                      )
                      .nombre;
                  return ListTile(
                    title: Text(p.nombre),
                    subtitle: Text('Categoria: $catName — Stock: ${p.stock}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
