import '../api/api_client.dart';
import '../../models/report/report_models.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<void> createReport({
    required String twizzId,
    required ReportReason reason,
    String? description,
  }) async {
    await _apiClient.post(
      '/reports',
      includeAuth: true,
      body: {
        'twizz_id': twizzId,
        'reason': reason.value,
        'description': description ?? '',
      },
    );
  }

  Future<ReportsResponse> getMyReports({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/reports/my?page=$page&limit=$limit',
      includeAuth: true,
    );
    return ReportsResponse.fromJson(response);
  }

  Future<ReportsResponse> getReportsAgainstMe({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get(
      '/reports/against-me?page=$page&limit=$limit',
      includeAuth: true,
    );
    return ReportsResponse.fromJson(response);
  }
}
