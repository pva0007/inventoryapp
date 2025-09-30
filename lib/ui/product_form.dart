import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/producto.dart';
import '../providers/producto_provider.dart';
import '../repositories/producto_repository.dart';
import '../providers/categoria_provider.dart';
import '../models/categoria.dart';

class ProductFormPage extends StatefulWidget {
  final String? productoId; // optional id when editing
  const ProductFormPage({super.key, this.productoId});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();
  String? _selectedCategoryId;
  // keep a lightweight cache of categories for the dropdown
  List<Categoria> _categorias = [];
  final TextEditingController _imageUrlCtrl = TextEditingController();
  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _precioCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _imageUrlCtrl.dispose();
    // no controller to dispose for category dropdown
    _stockCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If editing, try to prefill values from provider
    if (widget.productoId != null && widget.productoId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<ProductoProvider>(context, listen: false);
        final prod = provider.productos.firstWhere(
          (p) => p.id == widget.productoId,
          orElse: () => Producto(
            id: '',
            nombre: '',
            descripcion: '',
            stock: 0,
            precio: 0.0,
          ),
        );
        if (prod.id.isNotEmpty) {
          _nombreCtrl.text = prod.nombre;
          _descripcionCtrl.text = prod.descripcion;
          _selectedCategoryId = prod.categoryId;
          _imageUrlCtrl.text = prod.imageUrl ?? '';
          _stockCtrl.text = prod.stock.toString();
          _precioCtrl.text = prod.precio.toString();
          setState(() {});
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    Producto producto = Producto(
      id: '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      imageUrl: _imageUrlCtrl.text.trim().isEmpty
          ? null
          : _imageUrlCtrl.text.trim(),
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      precio: double.tryParse(_precioCtrl.text.trim()) ?? 0.0,
    );

    final provider = Provider.of<ProductoProvider>(context, listen: false);
    // If user picked a local image file, upload it first
    if (_pickedImageFile != null) {
      final repo = ProductoRepository();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await repo.uploadProductImage(
        _pickedImageFile!,
        filename,
      );
      producto = Producto(
        id: producto.id,
        nombre: producto.nombre,
        descripcion: producto.descripcion,
        categoryId: producto.categoryId,
        imageUrl: downloadUrl,
        tags: producto.tags,
        metadata: producto.metadata,
        stock: producto.stock,
        precio: producto.precio,
      );
    }

    await provider.addProducto(producto);

    if (!mounted) return;

    if (provider.error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${provider.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductoProvider>(context);
    final categoriaProvider = Provider.of<CategoriaProvider>(context);
    _categorias = categoriaProvider.categorias;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _imageUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Imagen URL'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          setState(() {
                            _pickedImageFile = File(picked.path);
                            _imageUrlCtrl.text = picked.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Elegir imagen'),
                    ),
                    const SizedBox(width: 12),
                    if (_pickedImageFile != null)
                      Image.file(
                        _pickedImageFile!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  items: _categorias
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombre),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _stockCtrl,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (int.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _precioCtrl,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                provider.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Crear'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
