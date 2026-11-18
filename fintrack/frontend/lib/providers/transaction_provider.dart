import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/transaction_model.dart';
import 'analytics_provider.dart';
import 'api_providers.dart';

class TransactionFilterState {
  final String filterType; // 'all', 'income', 'expense'
  final String filterCategory; // 'all' or category name
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionFilterState({
    this.filterType = 'all',
    this.filterCategory = 'all',
    this.searchQuery = '',
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    String? filterType,
    String? filterCategory,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) {
    return TransactionFilterState(
      filterType: filterType ?? this.filterType,
      filterCategory: filterCategory ?? this.filterCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionState {
  final bool isLoading;
  final bool isSaving;
  final List<TransactionModel> transactions;
  final int total;
  final TransactionFilterState filter;
  final String? errorMessage;

  TransactionState({
    this.isLoading = false,
    this.isSaving = false,
    this.transactions = const [],
    this.total = 0,
    required this.filter,
    this.errorMessage,
  });

  TransactionState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<TransactionModel>? transactions,
    int? total,
    TransactionFilterState? filter,
    String? errorMessage,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref ref;

  TransactionNotifier(this.ref)
      : super(
          TransactionState(
            filter: TransactionFilterState(),
          ),
        ) {
    loadTransactions();
  }

  void _invalidateAnalytics() {
    ref.invalidate(analyticsSummaryProvider);
    ref.invalidate(monthlyAnalyticsProvider);
    ref.invalidate(categoryAnalyticsProvider);
  }

  Future<void> loadTransactions({bool reset = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = ref.read(transactionServiceProvider);
      final response = await service.getTransactions(
        type: state.filter.filterType == 'all' ? null : state.filter.filterType,
        category: state.filter.filterCategory == 'all' ? null : state.filter.filterCategory,
        search: state.filter.searchQuery.isEmpty ? null : state.filter.searchQuery,
        startDate: state.filter.startDate,
        endDate: state.filter.endDate,
        limit: 100,
        offset: 0,
      );

      state = state.copyWith(
        isLoading: false,
        transactions: response.transactions,
        total: response.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load transactions: $e',
      );
    }
  }

  void setFilterType(String type) {
    state = state.copyWith(
      filter: state.filter.copyWith(filterType: type),
    );
    loadTransactions();
  }

  void setFilterCategory(String category) {
    state = state.copyWith(
      filter: state.filter.copyWith(filterCategory: category),
    );
    loadTransactions();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      filter: state.filter.copyWith(searchQuery: query),
    );
    loadTransactions();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        startDate: start,
        endDate: end,
        clearDates: start == null && end == null,
      ),
    );
    loadTransactions();
  }

  Future<bool> createTransaction(TransactionModel transaction) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final service = ref.read(transactionServiceProvider);
      await service.createTransaction(transaction);
      state = state.copyWith(isSaving: false);
      _invalidateAnalytics();
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to create transaction: $e',
      );
      return false;
    }
  }

  Future<bool> updateTransaction(int id, Map<String, dynamic> updates) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final service = ref.read(transactionServiceProvider);
      await service.updateTransaction(id, updates);
      state = state.copyWith(isSaving: false);
      _invalidateAnalytics();
      await loadTransactions();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update transaction: $e',
      );
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final service = ref.read(transactionServiceProvider);
      await service.deleteTransaction(id);
      _invalidateAnalytics();
      // Remove item optimistically
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
        total: state.total > 0 ? state.total - 1 : 0,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete transaction: $e');
      return false;
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});

// Recent transactions provider for dashboard (top 5)
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txState = ref.watch(transactionProvider);
  if (txState.transactions.length > 5) {
    return txState.transactions.sublist(0, 5);
  }
  return txState.transactions;
});
