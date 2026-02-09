import '../domain/models/impuesto.dart';
import '../services/impuestos_service.dart';
import 'base_provider.dart';

class ImpuestosProvider extends BaseProvider {
  ImpuestosProvider(this._service);

  final ImpuestosService _service;
  List<Impuesto> impuestos = [];

  Future<void> fetchImpuestos() async {
    setLoading(true);
    try {
      impuestos = await _service.fetchImpuestos();
      setError(null);
    } catch (error) {
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createImpuesto(Impuesto impuesto) async {
    setLoading(true);
    try {
      await _service.createImpuesto(impuesto);
      await fetchImpuestos();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateImpuesto(Impuesto impuesto) async {
    setLoading(true);
    try {
      await _service.updateImpuesto(impuesto);
      await fetchImpuestos();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> toggleActivo(Impuesto impuesto, bool activo) async {
    setLoading(true);
    try {
      await _service.updateImpuesto(impuesto.copyWith(activo: activo));
      await fetchImpuestos();
      return true;
    } catch (error) {
      setError(resolveError(error));
      return false;
    } finally {
      setLoading(false);
    }
  }
}
