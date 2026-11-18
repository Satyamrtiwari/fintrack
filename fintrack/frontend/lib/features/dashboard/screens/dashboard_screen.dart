import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final txState = ref.watch(transactionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = authState.user?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSummaryProvider);
          await ref.read(transactionProvider.notifier).loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Cards section
              summaryAsync.when(
                data: (summary) => Column(
                  children: [
                    // Total Net Savings Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
                                : [const Color(0xFFEEF2FF), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NET SAVINGS / BALANCE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (summary.savingsRate >= 0
                                            ? AppColors.income
                                            : AppColors.expense)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        summary.savingsRate >= 0
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        size: 14,
                                        color: summary.savingsRate >= 0
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${summary.savingsRate.toStringAsFixed(1)}% rate',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: summary.savingsRate >= 0
                                              ? AppColors.income
                                              : AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              CurrencyFormatter.format(
                                summary.netSavings,
                                symbol: settings.currencySymbol,
                              ),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: summary.netSavings >= 0
                                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                    : AppColors.expense,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${summary.transactionCount} transactions recorded',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Income and Expense Dual Stats
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Income',
                            amount: CurrencyFormatter.format(
                              summary.totalIncome,
                              symbol: settings.currencySymbol,
                            ),
                            icon: Icons.arrow_downward_rounded,
                            color: AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Total Expenses',
                            amount: CurrencyFormatter.format(
                              summary.totalExpenses,
                              symbol: settings.currencySymbol,
                            ),
                            icon: Icons.arrow_upward_rounded,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(analyticsSummaryProvider),
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.income,
                        side: const BorderSide(color: AppColors.income, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/transactions/add?type=income'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.remove, size: 20),
                      label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/transactions/add?type=expense'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Transactions List
              if (txState.isLoading && recentTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (recentTransactions.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  message: 'Add your first income or expense transaction to see it here.',
                  buttonText: 'Add Transaction',
                  onButtonPressed: () => context.push('/transactions/add'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    final item = recentTransactions[index];
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
            ],
          ),
        ),
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
}
