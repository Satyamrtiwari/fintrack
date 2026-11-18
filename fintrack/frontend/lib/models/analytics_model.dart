class AnalyticsSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;
  final int transactionCount;

  AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
    required this.transactionCount,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      netSavings: (json['net_savings'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
      transactionCount: json['transaction_count'] as int? ?? 0,
    );
  }

  factory AnalyticsSummary.empty() {
    return AnalyticsSummary(
      totalIncome: 0.0,
      totalExpenses: 0.0,
      netSavings: 0.0,
      savingsRate: 0.0,
      transactionCount: 0,
    );
  }
}

class MonthlyBreakdown {
  final String month;
  final int year;
  final double income;
  final double expense;
  final double net;

  MonthlyBreakdown({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyBreakdown(
      month: json['month'] as String,
      year: json['year'] as int,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final String type;
  final double totalAmount;
  final double percentage;
  final int count;

  CategoryBreakdown({
    required this.category,
    required this.type,
    required this.totalAmount,
    required this.percentage,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      type: json['type'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      count: json['count'] as int? ?? 0,
    );
  }
}

class CategoryAnalyticsResponse {
  final List<CategoryBreakdown> expenseCategories;
  final List<CategoryBreakdown> incomeCategories;

  CategoryAnalyticsResponse({
    required this.expenseCategories,
    required this.incomeCategories,
  });

  factory CategoryAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final expList = (json['expense_categories'] as List<dynamic>? ?? [])
        .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
    final incList = (json['income_categories'] as List<dynamic>? ?? [])
        .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
    return CategoryAnalyticsResponse(
      expenseCategories: expList,
      incomeCategories: incList,
    );
  }
}
