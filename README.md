# InventoryApp — Gestión de inventario (Flutter + Firebase)

Este proyecto es una aplicación Flutter de ejemplo para gestionar un inventario de productos, organizada por categorías (con soporte de jerarquía: categorías dentro de categorías) y con soporte para imágenes de producto mediante Firebase Storage.

El objetivo del README es dejar claro cómo está organizada la app, cómo desplegarla y cómo están estructuradas las colecciones en Firestore.

## Resumen rápido
- Flutter app con Provider para el estado.
- Backend: Firebase (Cloud Firestore + Firebase Storage) y otros servicios opcionales incluidos en `pubspec.yaml`.
- Soporta categorías jerárquicas (categorías padre en la colección `collections`, subcategorías en `categorias`).
- Productos almacenados en colecciones anidadas según la categoría (opción B):
	- Si la subcategoría tiene `parentId`: `collections/{parentId}/categorias/{categoryId}/productos/{productId}`
	- Si la categoría es padre (sin parentId): `collections/{categoryId}/productos/{productId}`
	- Fallback: `productos/{productId}` (top-level) para productos no categorizados o migraciones.
- Soporte para seleccionar imagen desde el dispositivo y subirla a Firebase Storage (se guarda el `imageUrl` en el documento del producto).

---

## Requisitos
- Flutter (compatible con la SDK indicado en `pubspec.yaml`).
- Un proyecto de Firebase configurado con Firestore y Firebase Storage.
- `google-services.json` (Android) y/o `GoogleService-Info.plist` (iOS) correctamente instalados en sus carpetas respectivas.

En este repositorio hay un archivo `app/google-services.json` (verifica que es el correcto para tu proyecto). Ajusta según sea necesario.

---

## Instalación y ejecución (rápida)
Abre una terminal (PowerShell en Windows) en la raíz del proyecto y ejecuta:

```powershell
flutter pub get
flutter analyze
flutter run -d <dispositivo>
```

Para pruebas locales en Android emulador o dispositivo físico conectado, sustituye `<dispositivo>` por el id del dispositivo o deja vacío para elegir.

---

## Dependencias relevantes
En `pubspec.yaml` encontrarás (entre otras):
- firebase_core, cloud_firestore, firebase_storage — integración con Firebase
- provider — gestión de estado
- image_picker — para seleccionar imágenes desde el dispositivo

Si agregas o actualizas paquetes, ejecuta `flutter pub get`.

---

## Estructura principal del código (archivos clave)
- `lib/models/categoria.dart` — Modelo de categoría (id, nombre, descripcion, imageUrl, parentId, metadata).
- `lib/models/producto.dart` — Modelo de producto (id, nombre, descripcion, categoryId, imageUrl, tags, metadata, stock, precio).
- `lib/repositories/categoria_repository.dart` — Acceso a Firestore para categorías. Es responsable de almacenar padres en `collections` y subcategorías en `categorias`.
- `lib/repositories/producto_repository.dart` — Acceso a Firestore para productos. Escribe/lee productos en rutas anidadas según la categoría (ver más arriba) y contiene `uploadProductImage` para subir imágenes a Storage.
- `lib/providers/categoria_provider.dart` — Provider para gestionar la lista de categorías y acciones CRUD.
- `lib/providers/producto_provider.dart` — Provider para productos (stream/list, add, update, delete y helpers de filtrado).
- `lib/ui/inventario_page.dart` — Página principal con listado de productos.
- `lib/ui/product_form.dart` — Formulario para crear/editar productos; admite seleccionar imagen desde el dispositivo y subirla.
- `lib/ui/categories_page.dart` y `lib/ui/category_form.dart` — Gestión de categorías (crear/editar/eliminar).
- `lib/ui/search_page.dart` — Búsqueda global sobre productos y categorías.

---

## Cómo funcionan las categorías jerárquicas
- Las categorías padre se guardan en la colección `collections`.
- Las subcategorías (que tienen `parentId`) se guardan en la colección `categorias`.
- El modelo `Categoria` incluye `parentId` (nullable). Si `parentId == null` se considera categoría padre.
- La UI actual muestra las categorías en lista; se puede mejorar para renderizar una vista en árbol (ExpansionTile) agrupando padres y sus hijos.

Si quieres que al crear/editar una categoría el formulario muestre un desplegable para elegir `parentId`, puedo añadirlo.

---

## Cómo funcionan los productos en Firestore (colecciones anidadas)
- Al guardar un producto, el repositorio comprueba `producto.categoryId` y resuelve la categoría a través de `CategoriaRepository`.
- Si la categoría tiene `parentId`: guarda en
	`collections/{parentId}/categorias/{categoryId}/productos`.
- Si la categoría es un padre (sin `parentId`): guarda en
	`collections/{categoryId}/productos`.
- Si no existe categoryId o la categoría no se encuentra: guarda en `productos` (fallback top-level).

Ventajas de este esquema:
- Organización clara por jerarquía y separación de datos por colección.
- Posibilidad de aplicar reglas y seguridad específicas por colección.

Inconvenientes:
- El código actual escucha todas las subcolecciones de productos (por cada categoría); esto puede no escalar bien si hay muchas categorías (muchas listeners).
- Opciones alternativas más escalables: mantener `productos` top-level y filtrar por `categoryId` (más simple), o indexar/migrar a un servicio de búsqueda.

---

## Imágenes de producto
- En el formulario de producto se puede elegir una imagen desde la galería (image_picker).
- El archivo se sube a Firebase Storage bajo `product_images/<timestamp>.jpg` mediante `ProductoRepository.uploadProductImage`.
- El documento del producto guarda `imageUrl` con la URL pública (download URL) que se usa para mostrar la imagen en la lista.

Requisitos:
- Habilita Firebase Storage en tu proyecto en la consola de Firebase.
- Ajusta las reglas de seguridad según tu política (desarrollo: permisiva; producción: autenticación y validación).

---

## Migraciones / notas de compatibilidad
- Lectura: `Producto.fromMap` soporta la antigua clave `categoria` como fallback para `categoryId`, de modo que los documentos antiguos siguen siendo legibles.
- Si deseas migrar todos los productos que usan `categoria` a `categoryId` o mover categorías existentes a la nueva estructura (`collections`), puedo agregar un pequeño script/migración que:
	1. Lee todos los valores `categoria` (texto).
	2. Crea entradas en `collections` o `categorias` según reglas que definamos.
	3. Actualiza cada producto para referenciar la nueva `categoryId`.

---

## Recomendaciones de seguridad y producción
- Revisa y endurece las reglas de Firestore y Storage.
- Evita reglas abiertas en producción. Usa autenticación y validaciones (por ejemplo: solo usuarios admin pueden crear categorías globales).
- Añade validaciones en servidor/lógica para evitar inconsistencias al reubicar o eliminar categorías padre.

---

## Comandos útiles
```powershell
# Obtener paquetes
flutter pub get
# Analizar código
flutter analyze
# Ejecutar en dispositivo/emulador
flutter run
```

---

## Próximos pasos que puedo implementar por ti
- Añadir selector de `parentId` en el formulario de categoría y vista en árbol (ExpansionTile) que muestre la jerarquía.
- Mejorar la escalabilidad de `getProductos()` evitando suscripciones masivas (paginación, queries por demanda).
- Implementar progresos y feedback en la subida de imágenes.
- Añadir migración automática para documentos antiguos.

Si quieres que implemente alguna de estas opciones, dime cuál y la implemento.

---

¡Listo! Si necesitas que traduzca o expanda alguna sección del README, o que agregue instrucciones particulares para despliegue (CI/CD, hosting, reglas de seguridad), dime y lo adapto.
