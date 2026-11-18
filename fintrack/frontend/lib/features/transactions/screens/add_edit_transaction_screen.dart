import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final int? transactionId;
  final String? initialType; // 'income' or 'expense'

  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
    this.initialType,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingItem = false;

  bool get isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null &&
        (widget.initialType == 'income' || widget.initialType == 'expense')) {
      _type = widget.initialType!;
    }

    if (isEdit) {
      _loadExistingTransaction();
    }
  }

  void _loadExistingTransaction() {
    // Find transaction from existing state
    final txList = ref.read(transactionProvider).transactions;
    final match = txList.firstWhere(
      (t) => t.id == widget.transactionId,
      orElse: () => TransactionModel(
        id: widget.transactionId,
        title: '',
        amount: 0,
        type: 'expense',
        category: '',
        transactionDate: DateTime.now(),
      ),
    );

    if (match.title.isNotEmpty) {
      _titleController.text = match.title;
      _amountController.text = match.amount.toStringAsFixed(2);
      _type = match.type.toLowerCase();
      _selectedCategory = match.category;
      _selectedDate = match.transactionDate;
      if (match.notes != null) {
        _notesController.text = match.notes!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than zero'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    bool success = false;
    if (isEdit) {
      final updates = <String, dynamic>{
        'title': _titleController.text.trim(),
        'amount': amount,
        'type': _type,
        'category': _selectedCategory,
        'transaction_date': DateFormatter.toIsoDate(_selectedDate),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };
      success = await ref
          .read(transactionProvider.notifier)
          .updateTransaction(widget.transactionId!, updates);
    } else {
      final newTx = TransactionModel(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _selectedCategory!,
        transactionDate: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      success = await ref
          .read(transactionProvider.notifier)
          .createTransaction(newTx);
    }

    if (success && mounted) {
      context.pop();
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
        title: Text(isEdit ? 'Edit Transaction' : 'New Transaction'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Segmented Switcher (Expense vs. Income)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _type = 'expense';
                                _selectedCategory = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'expense'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _type = 'income';
                                _selectedCategory = null;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _type == 'income' ? AppColors.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'income'
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amount Input
                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount (${settings.currencySymbol})',
                    hint: '0.00',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter transaction amount';
                      }
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Title Input
                  CustomTextField(
                    controller: _titleController,
                    label: 'Title / Description',
                    hint: _type == 'expense' ? 'e.g. Supermarket Groceries' : 'e.g. Monthly Salary',
                    prefixIcon: Icons.label_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Category Selector
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  categoriesAsync.when(
                    data: (categories) {
                      final filtered = categories
                          .where((c) => c.type.toLowerCase() == _type.toLowerCase())
                          .toList();

                      if (filtered.isEmpty) {
                        return const Text('No categories available.');
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filtered.map((cat) {
                          final isSelected = _selectedCategory == cat.name;
                          return ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            selectedColor: _type == 'expense' ? AppColors.expense : AppColors.income,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat.name;
                                });
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (_, __) => const Text('Could not load categories'),
                  ),

                  const SizedBox(height: 20),

                  // Transaction Date Picker Tile
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    tileColor: isDark ? AppColors.darkSurface : Colors.white,
                    leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                    title: const Text('Date'),
                    subtitle: Text(DateFormatter.format(_selectedDate)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: _pickDate,
                  ),

                  const SizedBox(height: 16),

                  // Notes (Optional)
                  CustomTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    hint: 'Additional details or memo...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  CustomButton(
                    text: isEdit ? 'Save Changes' : 'Record Transaction',
                    icon: Icons.check,
                    isLoading: txState.isSaving,
                    backgroundColor: _type == 'expense' ? AppColors.expense : AppColors.income,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
