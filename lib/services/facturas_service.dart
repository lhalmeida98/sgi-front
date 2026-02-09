import 'package:intl/intl.dart';

import '../domain/models/factura.dart';
import '../domain/models/factura_page.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class FacturasService {
  FacturasService(this._client);

  final ApiClient _client;

  Future<Factura> createFactura(Map<String, dynamic> payload) async {
    final response = await _client.post('/api/facturas', body: payload);
    final map = extractMap(response);
    if (map.isEmpty) {
      return Factura();
    }
    return Factura.fromJson(map);
  }

  Future<Factura> fetchEnProcesoFactura(int facturaId) async {
    final response = await _client.get('/api/facturas/$facturaId/en-proceso');
    final map = extractMap(response);
    return Factura.fromJson(map);
  }

  Future<Factura> fetchEstadoFactura(String numeroFactura) async {
    final response = await _client.get('/api/facturas/$numeroFactura/estado');
    final map = extractMap(response);
    return Factura.fromJson(map);
  }

  Future<List<Factura>> fetchEnProceso(int empresaId) async {
    final response = await _client.get(
      '/api/facturas/empresa/$empresaId/en-proceso',
    );
    final items = extractList(response);
    return items.map(Factura.fromJson).toList();
  }

  Future<FacturaPage> fetchTodas(
    int empresaId, {
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '$size',
    };
    if (fechaDesde != null) {
      query['fechaDesde'] = _formatDate(fechaDesde);
    }
    if (fechaHasta != null) {
      query['fechaHasta'] = _formatDate(fechaHasta);
    }
    final response = await _client.get(
      '/api/facturas/empresa/$empresaId',
      query: query,
    );
    final map = extractMap(response);
    final items = extractList(map['items'] ?? const []);
    return FacturaPage(
      items: items.map(Factura.fromJson).toList(),
      page: parseInt(map['page']) ?? page,
      size: parseInt(map['size']) ?? size,
      totalItems: parseInt(map['totalItems']) ?? items.length,
      totalPages: parseInt(map['totalPages']) ?? 1,
    );
  }

  Future<void> reenviarEnProceso(int empresaId) async {
    await _client.post(
      '/api/facturas/empresa/$empresaId/en-proceso/reenviar',
      body: {},
    );
  }

  Future<void> reenviarFactura(int facturaId) async {
    await _client.post(
      '/api/facturas/$facturaId/reenviar',
      body: {},
    );
  }

  Future<List<int>> fetchPdf(int facturaId) async {
    return _client.getBytes('/api/facturas/$facturaId/pdf');
  }

  Future<List<int>> fetchXml(int facturaId) async {
    return _client.getBytes('/api/facturas/$facturaId/xml');
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
