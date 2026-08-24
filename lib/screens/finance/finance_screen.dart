import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../services/finance_service.dart';
import '../../widgets/running_balance_card.dart';
import 'finance_summary_screen.dart';
import 'recurring_transactions_screen.dart';

class FinanceScreen extends StatefulWidget {  // Standard format, memorize for now.
  const FinanceScreen({super.key}); // When the rest of your app wants to navigate to this page, it calls this constructor.

  @override
  State<FinanceScreen> createState() => _FinanceScreenState(); // What this does: Whenever someone opens the FinanceScreen front door, 
}                                                              // immediately create the private _FinanceScreenState back room, and link them together.

class _FinanceScreenState extends State<FinanceScreen> {
  late FinanceService _financeService;            // late: It will be assigned a value before the UI uses it.
  final _formKey = GlobalKey<FormState>();        // Will be initialized in initState() later.
  DateTime _selectedMonth = DateTime.now();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final _budgetFormKey = GlobalKey<FormState>();  // GlobalKey: for checking errors later.

  // Form fields
  late TextEditingController _titleController;       // TextEditingController: a listener. Like a "spy" that monitors what the user inputs.
  late TextEditingController _amountController;
  late TextEditingController _budgetLimitController;
  late TextEditingController _baseBalanceController;
  late TextEditingController _searchController;
  String _selectedType = 'expense';
  String _selectedCategory = 'Food & Dining';
  String _typeFilter = 'all';
  bool _isSavingBudget = false;
  bool _isSavingTransaction = false;

  final List<String> _categories = [ // Square brackets "[]": for lists
    'Food & Dining',                 // Curly brackets "{}": Maps or Sets 
    'Transport',
    'Shopping',                      // _categories is gonna be the dropdown list later.
    'Housing',
    'Entertainment',
    'Utilities',
    'Other',
  ];

  final List<String> _types = ['income', 'expense'];

  @override
  void initState() { // initState runs before any pixel is painted by the screen.
    super.initState(); // FYI: super is short for superclass.
    _financeService = FinanceService();  // utilizing finance_service.dart code
    _titleController = TextEditingController(); 
    _amountController = TextEditingController();
    _budgetLimitController = TextEditingController();
    _baseBalanceController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();         // triggered once the screen (finance screen) is destroyed.
    _amountController.dispose();        // if not, the controllers will eat up the memory.
    _budgetLimitController.dispose();   // .dispose(): must actively remove the controllers. removed from memory. Basically, memory management.
    _baseBalanceController.dispose();
    _searchController.dispose();
    super.dispose(); // Golden Rule: super.iniState() - FIRST line, super.dispose() - LAST line.
  }

  void _showEditBaseBalanceDialog(double currentBaseBalance) {
    _baseBalanceController.text = currentBaseBalance.toStringAsFixed(2);
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> saveBaseBalance() async {
            final value = double.tryParse(_baseBalanceController.text.trim());
            if (value == null) {
              _showSnackBar(
                'Please enter a valid amount',
                backgroundColor: Colors.red.shade700,
              );
              return;
            }

            setDialogState(() => isSaving = true);

            try {
              await _financeService.updateBaseBalance(value);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              _showSnackBar('Base balance updated');
            } catch (e) {
              if (!mounted) return;
              _showSnackBar(
                e.toString().replaceFirst('Exception: ', ''),
                backgroundColor: Colors.red.shade700,
              );
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isSaving = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Edit Base Balance'),
            content: TextField(
              controller: _baseBalanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New balance (RM)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              enabled: !isSaving,
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : saveBaseBalance,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showBudgetForm() {
    _budgetLimitController.clear();
    var selectedBudgetCategory = 'Food & Dining';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _budgetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Monthly Budget',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set a spending limit per category. You will get an alert when you exceed it.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBudgetCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedBudgetCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetLimitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monthly Limit (RM)',
                        hintText: 'Enter budget limit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a limit';
                        }
                        final limit = double.tryParse(value!);
                        if (limit == null || limit <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSavingBudget
                            ? null
                            : () => _saveBudget(
                                  sheetContext,
                                  selectedBudgetCategory,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF185FA5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSavingBudget
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Budget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your budgets',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<BudgetModel>>(
                      stream: _financeService.getBudgets(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Could not load budgets: ${snapshot.error}');
                        }

                        final budgets = snapshot.data ?? [];
                        if (budgets.isEmpty) {
                          return Text(
                            'No budgets set yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          );
                        }

                        return Column(
                          children: budgets.map((budget) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(budget.category),
                              trailing: Text(
                                'RM ${budget.limitAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBudget(
    BuildContext sheetContext,
    String selectedBudgetCategory,
  ) async {
    if (!_budgetFormKey.currentState!.validate()) return;

    setState(() => _isSavingBudget = true);

    try {
      final budget = BudgetModel(
        id: '',
        category: selectedBudgetCategory,
        limitAmount: double.parse(_budgetLimitController.text),
      );

      await _financeService.setBudgetLimit(budget);

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (!mounted) return;
      _showSnackBar('Budget saved for $selectedBudgetCategory');
      _budgetLimitController.clear();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingBudget = false);
      }
    }
  }

  Future<void> _checkBudgetOverspend({required String category}) async {
    final budget = await _financeService.getBudgetForCategory(category);
    if (budget == null) return;

    final currentSpend = await _financeService.calculateCategorySpend(
      category,
      DateTime.now(),
    );

    if (currentSpend > budget.limitAmount) {
      if (!mounted) return;
      _showSnackBar(
        'Alert: You have exceeded your budget for $category!',
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  /// Open bottom sheet for adding/editing transactions
  void _showTransactionForm({TransactionModel? transaction}) {
    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toString();
      _selectedType = transaction.type;
      _selectedCategory = transaction.category;
    } else {
      _titleController.clear();
      _amountController.clear();
      _selectedType = 'expense';
      _selectedCategory = 'Food & Dining';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction == null ? 'Add Transaction' : 'Edit Transaction',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter transaction title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    // Auto-categorize based on title keywords (Sprint 1 ID 2)
                    if (value.trim().length >= 3) {
                      final suggested = FinanceService.autoCategorize(value);
                      if (suggested != 'Other' && suggested != _selectedCategory) {
                        setState(() => _selectedCategory = suggested);
                      }
                    }
                  },
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSavingTransaction
                        ? null
                        : () => _saveTransaction(transaction),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSavingTransaction
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            transaction == null
                                ? 'Add Transaction'
                                : 'Update Transaction',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (transaction != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _deleteTransaction(transaction.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Delete Transaction',
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Save new or updated transaction
  void _saveTransaction(TransactionModel? transaction) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingTransaction = true);

    try {
      final newTransaction = TransactionModel(
        id: transaction?.id ?? '',
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: DateTime.now(),
        type: _selectedType,
        category: _selectedCategory,
      );

      if (transaction == null) {
        await _financeService.addTransaction(newTransaction);
        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Transaction added successfully');
        if (newTransaction.type == 'expense') {
          await _checkBudgetOverspend(category: newTransaction.category);
        }
      } else {
        await _financeService.updateTransaction(newTransaction);
        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar('Transaction updated successfully');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingTransaction = false);
      }
    }
  }

  Future<void> _swipeDeleteTransaction(TransactionModel transaction) async {
    try {
      await _financeService.deleteTransaction(transaction.id);
      if (!mounted) return;
      _showSnackBar('Transaction deleted successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red.shade700,
      );
    }
  }

  /// Delete transaction with confirmation
  void _deleteTransaction(String id) async {
    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _financeService.deleteTransaction(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) { // Context is basically like a GPS for your current widget tree. Flutter needs it to search where you are.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFf2f3f7);
    final outlineColor = isDark ? const Color(0xFF727782) : const Color(0xFFc2c6d2);
    final primaryContainer = const Color(0xFF185FA5);

    return Scaffold(
      backgroundColor: scaffoldBg, // The background of the entire screen (Scaffold).
      appBar: AppBar( 
        backgroundColor: scaffoldBg, // The background for appbar (top section).
        elevation: 5, // drop shadow.
        title: Text('Finance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
        // "centerTitle: false," : If you want to force the title to the left
        actions: [ // automatically placed on the right. it's also a list : "[ ]".
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFF185FA5)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceSummaryScreen()),
              );
            },
            tooltip: 'View Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.repeat_rounded, color: Color(0xFF185FA5)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen()),
              );
            },
            tooltip: 'Recurring Transactions',
          ),
          TextButton.icon( // Designed to hold icon & text side-by-side.
            onPressed: _showBudgetForm,
            icon: const Icon(Icons.savings_outlined, size: 18, color: Color(0xFF185FA5)),
            label: const Text(
              'Set Budgets',
              style: TextStyle(
                color: Color(0xFF185FA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container( // Static placeholder user profile button.
            margin: const EdgeInsets.only(right: 20), // some spacing from the right edge.
            child: const CircleAvatar( // automatically converts square images to circle. standard for flutter user profiles.
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF185FA5), size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column( // Column main axis: Vertical (Top to Bottom).
          crossAxisAlignment: CrossAxisAlignment.start, // Column cross axis: Horizontal (Left to Right).
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: outlineColor.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: outlineColor),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: outlineColor),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            RunningBalanceCard(
              balanceStream: _financeService.watchRunningBalance(),
              onEditBaseBalance: _showEditBaseBalanceDialog,
              primaryContainer: primaryContainer,
            ),
            const SizedBox(height: 24),

            // Transactions List with StreamBuilder
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search title or category',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _typeFilter == 'all',
                        onSelected: (_) => setState(() => _typeFilter = 'all'),
                      ),
                      FilterChip(
                        label: const Text('Income'),
                        selected: _typeFilter == 'income',
                        onSelected: (_) => setState(() => _typeFilter = 'income'),
                      ),
                      FilterChip(
                        label: const Text('Expense'),
                        selected: _typeFilter == 'expense',
                        onSelected: (_) => setState(() => _typeFilter = 'expense'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<TransactionModel>>(
                    stream: _financeService.getTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryContainer));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}', style: TextStyle(color: textColor)),
                        );
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      final transactions = (snapshot.data ?? []).where((t) {
                        final inMonth = t.date.year == _selectedMonth.year &&
                            t.date.month == _selectedMonth.month;
                        if (!inMonth) return false;
                        if (_typeFilter != 'all' && t.type != _typeFilter) return false;
                        if (query.isEmpty) return true;
                        return t.title.toLowerCase().contains(query) ||
                            t.category.toLowerCase().contains(query);
                      }).toList();

                      if (transactions.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              query.isNotEmpty || _typeFilter != 'all'
                                  ? 'No matching transactions this month.'
                                  : 'No transactions yet. Add one to get started!',
                              style: TextStyle(color: subtextColor),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => Divider(color: outlineColor.withOpacity(0.2), height: 24),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isIncome = transaction.type == 'income';
                          final amountColor = isIncome ? const Color(0xFF137333) : textColor;
                          final amountSign = isIncome ? '+' : '-';
                          final iconColor = isIncome ? const Color(0xFF137333) : Colors.red;
                          final iconBg = isIncome ? const Color(0xFFE6F4EA) : const Color(0xFFFFEFE5);

                          return Dismissible(
                            key: ValueKey(transaction.id),
                            direction: DismissDirection.horizontal,
                            background: _dismissBackground(Alignment.centerLeft),
                            secondaryBackground:
                                _dismissBackground(Alignment.centerRight),
                            onDismissed: (_) =>
                                _swipeDeleteTransaction(transaction),
                            child: GestureDetector(
                              onTap: () =>
                                  _showTransactionForm(transaction: transaction),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              transaction.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subtextColor,
                                              ),
                                            ),
                                            Text(
                                              '${DateTime.now().difference(transaction.date).inDays}d ago',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$amountSign RM ${transaction.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: amountColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionForm(),
        backgroundColor: primaryContainer,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _dismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
    );
  }
}
