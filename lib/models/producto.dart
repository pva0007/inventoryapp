class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  // Use categoryId for a stable reference to a Categoria document in Firestore.
  // Keep 'categoria' string for backward compatibility if older records use it.
  final String? categoryId;
  final String? imageUrl;
  final List<String>? tags; // flexible classification for future
  final Map<String, dynamic>? metadata; // flexible extra fields
  final int stock;
  final double precio;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.categoryId,
    this.imageUrl,
    this.tags,
    this.metadata,
    required this.stock,
    required this.precio,
  });

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    // support old 'categoria' string field as a fallback
    final catId = data['categoryId'] ?? data['categoria'];
    return Producto(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      categoryId: catId,
      imageUrl: data['imageUrl'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      stock: (data['stock'] ?? 0) as int,
      precio: (data['precio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'stock': stock,
      'precio': precio,
    };
    if (categoryId != null) map['categoryId'] = categoryId;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (tags != null) map['tags'] = tags;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }
}
