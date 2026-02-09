import '../domain/models/factura.dart';
import '../services/facturas_service.dart';
import 'base_provider.dart';

class FacturasProvider extends BaseProvider {
  FacturasProvider(this._service);

  final FacturasService _service;
  List<Factura> facturasEnProceso = [];
  List<Factura> facturasSeguimiento = [];
  int page = 0;
  int size = 20;
  int totalItems = 0;
  int totalPages = 0;
  Factura? estadoFactura;

  Future<void> fetchEnProceso(int empresaId) async {
    setLoading(true);
    try {
      facturasEnProceso = await _service.fetchEnProceso(empresaId);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchSeguimiento(
    int empresaId, {
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int page = 0,
    int size = 20,
  }) async {
    setLoading(true);
    try {
      final start = fechaDesde ?? _firstDayOfMonth(DateTime.now());
      final end = fechaHasta ?? _lastDayOfMonth(start);
      final result = await _service.fetchTodas(
        empresaId,
        fechaDesde: start,
        fechaHasta: end,
        page: page,
        size: size,
      );
      facturasSeguimiento = result.items;
      this.page = result.page;
      this.size = result.size;
      totalItems = result.totalItems;
      totalPages = result.totalPages;
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  DateTime _firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  Future<bool> reenviarEnProceso(int empresaId) async {
    setLoading(true);
    try {
      await _service.reenviarEnProceso(empresaId);
      setError(null);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> reenviarFactura(int facturaId) async {
    setLoading(true);
    try {
      await _service.reenviarFactura(facturaId);
      setError(null);
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<List<int>?> fetchPdf(int facturaId) async {
    setLoading(true);
    try {
      final bytes = await _service.fetchPdf(facturaId);
      setError(null);
      return bytes;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<List<int>?> fetchXml(int facturaId) async {
    setLoading(true);
    try {
      final bytes = await _service.fetchXml(facturaId);
      setError(null);
      return bytes;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<Factura?> createFactura(Map<String, dynamic> payload) async {
    setLoading(true);
    try {
      final factura = await _service.createFactura(payload);
      setError(null);
      return factura;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<Factura?> fetchEnProcesoFactura(int facturaId) async {
    setLoading(true);
    try {
      final factura = await _service.fetchEnProcesoFactura(facturaId);
      setError(null);
      return factura;
    } catch (error) {
      setError(resolveError(error));
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchEstado(String numeroFactura) async {
    setLoading(true);
    try {
      estadoFactura = await _service.fetchEstadoFactura(numeroFactura);
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }
}
