import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/producto_provider.dart';
import 'product_form.dart';
import 'categories_page.dart';
import 'search_page.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CategoriesPage())),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.productos.length,
              itemBuilder: (context, index) {
                final producto = provider.productos[index];
                return Card(
                  child: ListTile(
                    leading:
                        producto.imageUrl != null &&
                            producto.imageUrl!.isNotEmpty
                        ? Image.network(
                            producto.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(Icons.inventory),
                          ),
                    title: Text(producto.nombre),
                    subtitle: Text(
                      "Stock: ${producto.stock}, Precio: ${producto.precio}€",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductFormPage(productoId: producto.id),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => provider.deleteProducto(producto.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProductFormPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
