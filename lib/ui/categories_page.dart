import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categoria_provider.dart';
import 'category_form.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoriaProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.categorias.length,
              itemBuilder: (context, index) {
                final c = provider.categorias[index];
                return ListTile(
                  title: Text(c.nombre),
                  subtitle: Text(c.descripcion ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryFormPage(categoria: c),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => provider.deleteCategoria(c.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CategoryFormPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
