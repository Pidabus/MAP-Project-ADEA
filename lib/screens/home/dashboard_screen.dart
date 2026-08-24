import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/task_model.dart';
import '../../models/transaction_model.dart';
import '../../models/goal_model.dart';
import '../../models/reminder_model.dart';
import '../../services/finance_service.dart';
import '../../services/task_service.dart';
import '../../services/goal_service.dart';
import '../../services/reminder_service.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabSwitch;
  const DashboardScreen({super.key, this.onTabSwitch});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();
  final TaskService _taskService = TaskService();
  final GoalService _goalService = GoalService();
  final ReminderService _reminderService = ReminderService();

  late Stream<List<TaskModel>> _tasksStream;
  late Stream<List<TransactionModel>> _transactionsStream;
  late Stream<List<GoalModel>> _goalsStream;
  late Stream<ReminderModel?> _urgentReminderStream;
  late Stream<double> _runningBalanceStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = _taskService.getTasks();
    _transactionsStream = _financeService.getTransactions();
    _goalsStream = _goalService.getGoals();
    _urgentReminderStream = _reminderService.getMostUrgentReminder();
    _runningBalanceStream = _financeService.watchRunningBalance().map((summary) => summary.runningBalance);
  }

  // ─── FAB Speed Dial bottom sheet ───────────────────────────────────
  void _showSpeedDialSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161622) : Colors.white;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -5),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _speedDialItem(
                    label: 'Transaction',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF4285F4),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddTransactionSheet();
                    },
                  ),
                  _speedDialItem(
                    label: 'Task',
                    icon: Icons.checklist_rounded,
                    color: const Color(0xFFEA4335),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddTaskSheet();
                    },
                  ),
                  _speedDialItem(
                    label: 'Goal',
                    icon: Icons.track_changes_rounded,
                    color: const Color(0xFF34A853),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddGoalSheet();
                    },
                  ),
                  _speedDialItem(
                    label: 'Reminder',
                    icon: Icons.notifications_rounded,
                    color: const Color(0xFFFBBC05),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddReminderSheet();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedDialItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : const Color(0xFF424751),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Add Sheets ──────────────────────────────────────────────

  void _showAddTransactionSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'expense';
    String selectedCategory = 'Food & Dining';
    var isSaving = false;

    final categories = [
      'Food & Dining',
      'Transport',
      'Shopping',
      'Housing',
      'Entertainment',
      'Utilities',
      'Salary',
      'Freelance',
      'Other',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

          // Auto-categorize based on title text
          void onTitleChanged(String title) {
            final lower = title.toLowerCase().trim();
            String? suggested;

            if (lower.contains('kfc') ||
                lower.contains('mcdonald') ||
                lower.contains('food') ||
                lower.contains('starbucks') ||
                lower.contains('dinner') ||
                lower.contains('lunch') ||
                lower.contains('cafe')) {
              suggested = 'Food & Dining';
            } else if (lower.contains('grab') ||
                lower.contains('uber') ||
                lower.contains('taxi') ||
                lower.contains('petrol') ||
                lower.contains('car') ||
                lower.contains('bus')) {
              suggested = 'Transport';
            } else if (lower.contains('salary') ||
                lower.contains('wage') ||
                lower.contains('paycheck')) {
              suggested = 'Salary';
            } else if (lower.contains('freelance') ||
                lower.contains('gig') ||
                lower.contains('upwork')) {
              suggested = 'Freelance';
            } else if (lower.contains('netflix') ||
                lower.contains('spotify') ||
                lower.contains('movie') ||
                lower.contains('game')) {
              suggested = 'Entertainment';
            } else if (lower.contains('rent') ||
                lower.contains('room') ||
                lower.contains('apartment')) {
              suggested = 'Housing';
            } else if (lower.contains('electric') ||
                lower.contains('water') ||
                lower.contains('wifi') ||
                lower.contains('bill')) {
              suggested = 'Utilities';
            } else if (lower.contains('shop') ||
                lower.contains('lazada') ||
                lower.contains('shopee') ||
                lower.contains('mall') ||
                lower.contains('clothes')) {
              suggested = 'Shopping';
            }

            if (suggested != null && suggested != selectedCategory) {
              setSheetState(() => selectedCategory = suggested!);
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);
            try {
              final amount = double.parse(amountController.text.trim());
              await _financeService.addTransaction(TransactionModel(
                id: '',
                title: titleController.text.trim(),
                amount: amount,
                date: DateTime.now(),
                type: selectedType,
                category: selectedCategory,
              ));
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            } catch (e) {
              setSheetState(() => isSaving = false);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. KFC Dinner',
                    ),
                    onChanged: onTitleChanged,
                    validator: (v) => v!.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (RM)',
                      hintText: '0.00',
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid number' : null,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward_rounded, size: 16)),
                      ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward_rounded, size: 16)),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setSheetState(() => selectedType = selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFF4285F4),
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (v) => setSheetState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4)),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Transaction'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDueDate;
    DateTime? selectedReminderTime;
    var isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

          Future<void> pickDueDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setSheetState(() => selectedDueDate = picked);
            }
          }

          Future<void> pickReminderTime() async {
            final datePicked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (datePicked == null) return;

            if (!context.mounted) return;
            final timePicked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (timePicked == null) return;

            setSheetState(() {
              selectedReminderTime = DateTime(
                datePicked.year, datePicked.month, datePicked.day,
                timePicked.hour, timePicked.minute,
              );
            });
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);
            try {
              await _taskService.addTask(TaskModel(
                id: '',
                title: titleController.text.trim(),
                isCompleted: false,
                dueDate: selectedDueDate,
                reminderDateTime: selectedReminderTime,
              ));
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            } catch (e) {
              setSheetState(() => isSaving = false);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g. Read Flutter book',
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFFEA4335)),
                    title: Text(selectedDueDate == null
                        ? 'Set Due Date'
                        : 'Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'),
                    onTap: pickDueDate,
                    trailing: selectedDueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setSheetState(() => selectedDueDate = null),
                          )
                        : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded, color: Color(0xFFEA4335)),
                    title: Text(selectedReminderTime == null
                        ? 'Set Alert Reminder'
                        : 'Alert: ${selectedReminderTime!.hour}:${selectedReminderTime!.minute.toString().padLeft(2, '0')} on ${selectedReminderTime!.day}/${selectedReminderTime!.month}'),
                    onTap: pickReminderTime,
                    trailing: selectedReminderTime != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setSheetState(() => selectedReminderTime = null),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Task'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddGoalSheet() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDeadline;
    var isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

          Future<void> pickDeadline() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) {
              setSheetState(() => selectedDeadline = picked);
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);
            try {
              final title = titleController.text.trim();
              final target = double.parse(targetController.text.trim());
              final unit = unitController.text.trim();
              final resolvedUnit = GoalModel.resolveUnit(unit, title);

              await _goalService.addGoal(GoalModel(
                id: '',
                title: title,
                targetValue: target,
                currentValue: 0.0,
                deadline: selectedDeadline,
                unit: resolvedUnit,
              ));
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            } catch (e) {
              setSheetState(() => isSaving = false);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Title',
                      hintText: 'e.g. Save for New Laptop or Run 50km',
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter goal title' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: targetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Target Value',
                            hintText: 'e.g. 3000',
                          ),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid number' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'RM / km / kg',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.date_range_rounded, color: Color(0xFF34A853)),
                    title: Text(selectedDeadline == null
                        ? 'Set Deadline'
                        : 'Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'),
                    onTap: pickDeadline,
                    trailing: selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setSheetState(() => selectedDeadline = null),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34A853)),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Goal'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddReminderSheet() {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = DateTime.now().add(const Duration(minutes: 30));
    bool isUrgent = false;
    var isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

          Future<void> pickDateTime() async {
            final datePicked = await showDatePicker(
              context: context,
              initialDate: selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (datePicked == null) return;

            if (!context.mounted) return;
            final timePicked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(selectedDateTime),
            );
            if (timePicked == null) return;

            setSheetState(() {
              selectedDateTime = DateTime(
                datePicked.year, datePicked.month, datePicked.day,
                timePicked.hour, timePicked.minute,
              );
            });
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);
            try {
              await _reminderService.addReminder(ReminderModel(
                id: '',
                title: titleController.text.trim(),
                dateTime: selectedDateTime,
                isUrgent: isUrgent,
                isActive: true,
              ));
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            } catch (e) {
              setSheetState(() => isSaving = false);
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Reminder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Reminder Title',
                      hintText: 'e.g. Call Mom or Buy groceries',
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.alarm_rounded, color: Color(0xFFFBBC05)),
                    title: Text('Date & Time: ${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} ${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}'),
                    onTap: pickDateTime,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Mark as Urgent (Yellow Alert)'),
                    value: isUrgent,
                    onChanged: (v) => setSheetState(() => isUrgent = v ?? false),
                    activeColor: const Color(0xFFFBBC05),
                    checkColor: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBC05),
                      foregroundColor: Colors.black,
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper: Format remaining time for upcoming reminder
  String _formatRemainingTime(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Passed';
    if (diff.inDays > 0) return 'In ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0) return 'In ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
    return 'In ${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF424751);
    final scaffoldBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF185FA5),
                    child: Text(
                      state.user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFe2e0fc),
                child: Icon(Icons.person, color: Color(0xFF004782)),
              );
            },
          ),
        ),
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated ? state.user.name : 'Productive';
            final hour = DateTime.now().hour;
            final greeting = hour < 12
                ? 'Good morning'
                : hour < 18
                    ? 'Good afternoon'
                    : 'Good evening';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Structured Vitality',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtextColor,
                  ),
                ),
                Text(
                  '$greeting, $name! ✨',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            );
          },
        ),
        titleSpacing: 16,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSpeedDialSheet,
        tooltip: 'Quick Add Speed Dial',
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grid Title
            Text(
              'Your Dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // 4-Quadrant Grid (2x2)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                // 1. Finance (Blue)
                StreamBuilder<double>(
                  stream: _runningBalanceStream,
                  builder: (context, balanceSnapshot) {
                    final balance = balanceSnapshot.data ?? 0.0;
                    return StreamBuilder<List<TransactionModel>>(
                      stream: _transactionsStream,
                      builder: (context, txSnapshot) {
                        final txList = txSnapshot.data ?? [];
                        final lastTx = txList.isNotEmpty ? txList.first.title : 'No transactions';
                        return _quadrantCard(
                          title: 'Finance',
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF4285F4),
                          content: 'RM ${balance.toStringAsFixed(2)}',
                          subcontent: 'Last: $lastTx',
                          onTap: () => widget.onTabSwitch?.call(1),
                        );
                      },
                    );
                  },
                ),

                // 2. Tasks (Red)
                StreamBuilder<List<TaskModel>>(
                  stream: _tasksStream,
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? [];
                    final pending = tasks.where((t) => !t.isCompleted).toList();
                    final topTask = pending.isNotEmpty ? pending.first.title : 'No pending tasks';
                    return _quadrantCard(
                      title: 'Tasks',
                      icon: Icons.checklist_rounded,
                      color: const Color(0xFFEA4335),
                      content: '${pending.length} Pending',
                      subcontent: topTask,
                      onTap: () => widget.onTabSwitch?.call(2),
                    );
                  },
                ),

                // 3. Goals (Green)
                StreamBuilder<List<GoalModel>>(
                  stream: _goalsStream,
                  builder: (context, snapshot) {
                    final goals = snapshot.data ?? [];
                    var avgProgress = 0.0;
                    if (goals.isNotEmpty) {
                      final total = goals.fold<double>(0, (sum, g) => sum + g.progressFraction);
                      avgProgress = total / goals.length;
                    }
                    final topGoal = goals.isNotEmpty ? goals.first.title : 'No goals created';
                    return _quadrantCard(
                      title: 'Goals',
                      icon: Icons.track_changes_rounded,
                      color: const Color(0xFF34A853),
                      content: '${(avgProgress * 100).round()}% Completed',
                      subcontent: topGoal,
                      isGoal: true,
                      progressFraction: avgProgress,
                      onTap: () => widget.onTabSwitch?.call(3),
                    );
                  },
                ),

                // 4. Reminders (Yellow)
                StreamBuilder<ReminderModel?>(
                  stream: _urgentReminderStream,
                  builder: (context, snapshot) {
                    final reminder = snapshot.data;
                    final title = reminder?.title ?? 'No reminders';
                    final remaining = reminder != null ? _formatRemainingTime(reminder.dateTime) : 'All caught up';
                    return _quadrantCard(
                      title: 'Reminders',
                      icon: Icons.notifications_rounded,
                      color: const Color(0xFFFBBC05),
                      content: remaining,
                      subcontent: title,
                      onTap: () => widget.onTabSwitch?.call(4),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quadrantCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
    required String subcontent,
    required VoidCallback onTap,
    bool isGoal = false,
    double progressFraction = 0.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subTextThemeColor = isDark ? const Color(0xFFC2C6D2) : const Color(0xFF424751);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isGoal) ...[
              Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progressFraction,
                    strokeWidth: 6,
                    color: color,
                    backgroundColor: color.withOpacity(0.15),
                  ),
                ),
              ),
              const Spacer(),
            ] else ...[
              Text(
                content,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textThemeColor,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Text(
              subcontent,
              style: TextStyle(
                fontSize: 12,
                color: subTextThemeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
