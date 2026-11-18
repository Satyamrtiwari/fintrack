import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_model.dart';
import 'api_providers.dart';

final analyticsSummaryProvider = FutureProvider.autoDispose<AnalyticsSummary>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getSummary();
});

final monthlyAnalyticsProvider = FutureProvider.autoDispose<List<MonthlyBreakdown>>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getMonthly(months: 6);
});

final categoryAnalyticsProvider = FutureProvider.autoDispose<CategoryAnalyticsResponse>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return await service.getCategories();
});
