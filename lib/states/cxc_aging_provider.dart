import '../domain/models/cxc_aging_report.dart';
import '../services/cxc_reportes_service.dart';
import 'base_provider.dart';

class CxcAgingProvider extends BaseProvider {
  CxcAgingProvider(this._service);

  final CxcReportesService _service;
  CxcAgingReport? report;

  Future<void> fetchReport({int? clienteId}) async {
    setLoading(true);
    try {
      report = await _service.fetchAging(clienteId: clienteId);
      setError(null);
    } catch (error) {
      report = null;
      setError(resolveError(error));
    } finally {
      setLoading(false);
    }
  }
}
