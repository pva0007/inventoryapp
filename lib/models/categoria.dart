class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? imageUrl;
  final String? parentId; // for hierarchical categories in future
  final Map<String, dynamic>? metadata; // flexible extra data

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imageUrl,
    this.parentId,
    this.metadata,
  });

  factory Categoria.fromMap(String id, Map<String, dynamic> data) {
    return Categoria(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'],
      imageUrl: data['imageUrl'],
      parentId: data['parentId'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'nombre': nombre};
    if (descripcion != null) map['descripcion'] = descripcion;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (parentId != null) map['parentId'] = parentId;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }
}
