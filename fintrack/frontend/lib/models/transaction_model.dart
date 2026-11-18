class TransactionModel {
  final int? id;
  final int? userId;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime transactionDate;
  final String? notes;
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.transactionDate,
    this.notes,
    this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final dateStr =
        "${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}";
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'transaction_date': dateStr,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    if (userId != null) map['user_id'] = userId;
    return map;
  }

  TransactionModel copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    String? type,
    String? category,
    DateTime? transactionDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TransactionListResponse {
  final List<TransactionModel> transactions;
  final int total;
  final int limit;
  final int offset;

  TransactionListResponse({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return TransactionListResponse(
      transactions: list,
      total: json['total'] as int? ?? list.length,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
