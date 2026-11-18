import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../services/analytics_service.dart';
import '../services/category_service.dart';
import 'auth_provider.dart';

// Must be overridden in ProviderScope in main.dart after initializing SharedPreferences
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized first.');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(
    storageService: storage,
    onUnauthorized: () {
      ref.read(authProvider.notifier).handleUnauthorized();
    },
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthService(apiClient: client, storageService: storage);
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final client = ref.watch(apiClientProvider);
  return TransactionService(apiClient: client);
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AnalyticsService(apiClient: client);
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CategoryService(apiClient: client);
});
