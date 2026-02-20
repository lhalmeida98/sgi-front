import '../domain/models/cxc_aging_report.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class CxcReportesService {
  CxcReportesService(this._client);

  final ApiClient _client;

  Future<CxcAgingReport> fetchAging({int? clienteId}) async {
    final response = await _client.get(
      '/api/reportes/cxc/aging',
      query: clienteId == null ? null : {'clienteId': '$clienteId'},
    );
    final map = extractMap(response);
    return CxcAgingReport.fromJson(map);
  }
}
