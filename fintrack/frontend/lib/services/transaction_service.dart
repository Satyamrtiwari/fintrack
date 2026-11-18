import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/utils/date_formatter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final ApiClient apiClient;

  TransactionService({required this.apiClient});

  Future<TransactionListResponse> getTransactions({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 50,
    int offset = 0,
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sort_order': sortOrder,
    };
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category;
    }
    if (startDate != null) {
      queryParams['start_date'] = DateFormatter.toIsoDate(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormatter.toIsoDate(endDate);
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await apiClient.get(
      ApiConstants.transactions,
      queryParams: queryParams,
    );

    return TransactionListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final response = await apiClient.post(
      ApiConstants.transactions,
      body: transaction.toJson(),
    );
    return TransactionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransactionById(int id) async {
    final response = await apiClient.get('${ApiConstants.transactions}/$id');
    return TransactionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<TransactionModel> updateTransaction(
    int id,
    Map<String, dynamic> updates,
  ) async {
    final response = await apiClient.put(
      '${ApiConstants.transactions}/$id',
      body: updates,
    );
    return TransactionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(int id) async {
    await apiClient.delete('${ApiConstants.transactions}/$id');
  }
}
