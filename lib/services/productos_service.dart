import '../domain/models/inventario.dart';
import '../domain/models/producto.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';
import 'bodegas_service.dart';
import 'categorias_service.dart';
import 'impuestos_service.dart';
import 'inventarios_service.dart';

class ProductosService {
  ProductosService(this._client);

  final ApiClient _client;
  late final CategoriasService _categoriasService = CategoriasService(_client);
  late final ImpuestosService _impuestosService = ImpuestosService(_client);
  late final BodegasService _bodegasService = BodegasService(_client);
  late final InventariosService _inventariosService =
      InventariosService(_client);

  Future<List<Producto>> fetchProductos() async {
    final response = await _client.get('/api/productos');
    final items = extractList(response);
    return items.map(Producto.fromJson).toList();
  }

  Future<Producto> fetchProductoByCodigo(String codigo) async {
    final response = await _client.get(
      '/api/productos/buscar',
      query: {'codigo': codigo},
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      throw ApiException('Producto no encontrado.', statusCode: 404);
    }
    return Producto.fromJson(map);
  }

  Future<Producto> createProducto(Producto producto) async {
    _validateCreatePayload(producto);
    await _validateCategoria(producto.categoriaId);
    await _validateImpuesto(producto.impuestoId);
    final bodegaId = producto.bodegaId!;
    await _validateBodega(bodegaId);

    final payload = {
      'codigo': producto.codigo,
      'descripcion': producto.descripcion,
      'precioUnitario': producto.precioUnitario,
      'categoriaId': producto.categoriaId,
      'impuestoId': producto.impuestoId,
      'proveedorId': producto.proveedorId,
      'bodegaId': bodegaId,
      'costo': producto.costo,
      'vendible': producto.vendible,
      'codigoBarras': producto.codigoBarras ?? '',
    };
    final response = await _client.post(
      '/api/productos',
      body: payload,
    );
    final map = extractMap(response);
    var created = map.isEmpty ? producto : Producto.fromJson(map);
    var productoId = created.id;
    if (productoId == null) {
      final fetched = await fetchProductoByCodigo(producto.codigo);
      productoId = fetched.id;
      created = fetched;
    }
    if (productoId == null) {
      throw ApiException('No se pudo determinar el ID del producto creado.');
    }
    await _inventariosService.upsertInventario(
      Inventario(
        productoId: productoId,
        bodegaId: bodegaId,
        stockActual: 0,
        stockMinimo: 0,
        stockMaximo: 0,
        ubicacion: '',
        costoPromedio: producto.costo!,
      ),
    );
    return created.copyWith(
      proveedorId: producto.proveedorId,
      bodegaId: bodegaId,
      costo: producto.costo,
    );
  }

  Future<Producto> updateProducto(Producto producto) async {
    if (producto.id == null) {
      throw ApiException('Producto sin ID para actualizar.');
    }
    final payload = {
      'codigo': producto.codigo,
      'descripcion': producto.descripcion,
      'precioUnitario': producto.precioUnitario,
      'categoriaId': producto.categoriaId,
      'impuestoId': producto.impuestoId,
      if (producto.proveedorId != null) 'proveedorId': producto.proveedorId,
      if (producto.bodegaId != null) 'bodegaId': producto.bodegaId,
      if (producto.costo != null) 'costo': producto.costo,
      'vendible': producto.vendible,
      'codigoBarras': producto.codigoBarras ?? '',
    };
    final response = await _client.put(
      '/api/productos/${producto.id}',
      body: payload,
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return producto;
    }
    return Producto.fromJson(map);
  }

  Future<Producto?> updateVendible({
    required int productoId,
    required bool vendible,
  }) async {
    final response = await _client.put(
      '/api/productos/$productoId/vendible',
      body: {'vendible': vendible},
    );
    final map = extractMap(response);
    if (map.isEmpty) {
      return null;
    }
    return Producto.fromJson(map);
  }

  void _validateCreatePayload(Producto producto) {
    if (producto.categoriaId <= 0) {
      throw ApiException('Categoria invalida.');
    }
    if (producto.impuestoId <= 0) {
      throw ApiException('Impuesto invalido.');
    }
    if (producto.bodegaId == null || producto.bodegaId! <= 0) {
      throw ApiException('Bodega invalida.');
    }
    if (producto.costo == null || producto.costo! <= 0) {
      throw ApiException('Costo invalido.');
    }
  }

  Future<void> _validateCategoria(int categoriaId) async {
    final categorias = await _categoriasService.fetchCategorias();
    final exists = categorias.any((categoria) => categoria.id == categoriaId);
    if (!exists) {
      throw ApiException('La categoria seleccionada no existe.');
    }
  }

  Future<void> _validateImpuesto(int impuestoId) async {
    final impuestos = await _impuestosService.fetchImpuestos();
    final exists = impuestos.any((impuesto) => impuesto.id == impuestoId);
    if (!exists) {
      throw ApiException('El impuesto seleccionado no existe.');
    }
  }

  Future<void> _validateBodega(int bodegaId) async {
    final bodegas = await _bodegasService.fetchBodegas();
    final exists = bodegas.any((bodega) => bodega.id == bodegaId);
    if (!exists) {
      throw ApiException('La bodega seleccionada no existe.');
    }
  }
}
