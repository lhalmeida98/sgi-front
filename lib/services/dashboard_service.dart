import '../domain/models/dashboard_resumen.dart';
import '../utils/json_utils.dart';
import 'api_client.dart';

class DashboardService {
  DashboardService(this._client);

  final ApiClient _client;

  Future<DashboardResumen> fetchResumen({int? empresaId}) async {
    final response = await _client.get(
      '/api/dashboard/resumen',
      query: empresaId == null ? null : {'empresaId': '$empresaId'},
    );
    final map = extractMap(response);
    return DashboardResumen.fromJson(map);
  }
}
