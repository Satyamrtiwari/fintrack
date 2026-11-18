import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final currentFilter = ref.read(transactionProvider).filter;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: currentFilter.startDate != null && currentFilter.endDate != null
          ? DateTimeRange(start: currentFilter.startDate!, end: currentFilter.endDate!)
          : null,
    );

    if (picked != null) {
      ref.read(transactionProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          if (txState.filter.startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear Date Filter',
              onPressed: () {
                ref.read(transactionProvider.notifier).setDateRange(null, null);
              },
            ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Filter by Date',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(transactionProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Type Segment Filter Chips (All, Income, Expense)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All', txState.filter.filterType),
                const SizedBox(width: 8),
                _buildFilterChip('income', 'Income', txState.filter.filterType, color: AppColors.income),
                const SizedBox(width: 8),
                _buildFilterChip('expense', 'Expense', txState.filter.filterType, color: AppColors.expense),
                const SizedBox(width: 12),

                // Category Dropdown Filter
                categoriesAsync.when(
                  data: (categories) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: txState.filter.filterCategory,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          ...categories.map(
                            (c) => DropdownMenuItem(value: c.name, child: Text(c.name)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(transactionProvider.notifier).setFilterCategory(val);
                          }
                        },
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Active Date Range Indicator
          if (txState.filter.startDate != null && txState.filter.endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormatter.formatShort(txState.filter.startDate!)} - ${DateFormatter.formatShort(txState.filter.endDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        ref.read(transactionProvider.notifier).setDateRange(null, null);
                      },
                      child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

          // Transactions List or Empty State
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(transactionProvider.notifier).loadTransactions();
              },
              child: txState.isLoading && txState.transactions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : txState.transactions.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No transactions found',
                          message: 'Try adjusting your filters or record a new transaction.',
                          buttonText: 'Add Transaction',
                          onButtonPressed: () => context.push('/transactions/add'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: txState.transactions.length,
                          itemBuilder: (context, index) {
                            final item = txState.transactions[index];
                            return TransactionTile(
                              transaction: item,
                              currencySymbol: settings.currencySymbol,
                              onEdit: () => context.push('/transactions/edit/${item.id}'),
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: Text('Are you sure you want to delete "${item.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.expense,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && item.id != null) {
                                  await ref
                                      .read(transactionProvider.notifier)
                                      .deleteTransaction(item.id!);
                                }
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
        onPressed: () => context.push('/transactions/add'),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentSelected, {Color? color}) {
    final isSelected = currentSelected == value;
    final chipColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: chipColor,
      onSelected: (_) {
        ref.read(transactionProvider.notifier).setFilterType(value);
      },
    );
  }
}
