import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/utils/date_formatter.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  final ApiClient apiClient;

  AnalyticsService({required this.apiClient});

  Future<AnalyticsSummary> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = DateFormatter.toIsoDate(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormatter.toIsoDate(endDate);
    }

    final response = await apiClient.get(
      ApiConstants.analyticsSummary,
      queryParams: queryParams,
    );

    return AnalyticsSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MonthlyBreakdown>> getMonthly({int months = 6}) async {
    final response = await apiClient.get(
      ApiConstants.analyticsMonthly,
      queryParams: {'months': months},
    );

    final map = response as Map<String, dynamic>;
    final list = (map['monthly_data'] as List<dynamic>? ?? [])
        .map((e) => MonthlyBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<CategoryAnalyticsResponse> getCategories({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = DateFormatter.toIsoDate(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormatter.toIsoDate(endDate);
    }

    final response = await apiClient.get(
      ApiConstants.analyticsCategories,
      queryParams: queryParams,
    );

    return CategoryAnalyticsResponse.fromJson(response as Map<String, dynamic>);
  }
}
