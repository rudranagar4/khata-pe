import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../properties/data/property_repository.dart';
import '../data/expense_repository.dart';
import 'add_expense_dialog.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _propertyFilter;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final properties = ref.watch(propertiesProvider);

    final filtered = _propertyFilter == null
        ? expenses
        : expenses.where((e) => e.propertyId == _propertyFilter).toList();

    final totalAmount = filtered.fold(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('Expenses (मकान के खर्चे)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_fab',
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => AddExpenseDialog.show(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Total Spent Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Expenses', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalAmount),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                    ),
                  ],
                ),
                if (properties.isNotEmpty)
                  DropdownButton<String?>(
                    value: _propertyFilter,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    hint: const Text('All Buildings', style: TextStyle(color: AppColors.textSecondary)),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Buildings')),
                      ...properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (val) => setState(() => _propertyFilter = val),
                  ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade600),
                        const SizedBox(height: 14),
                        const Text('No expenses recorded yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Record repairs, society maintenance, and taxes here', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () => AddExpenseDialog.show(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Expense'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final exp = filtered[index];
                      final prop = properties.where((p) => p.id == exp.propertyId).firstOrNull;

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A1517),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.build_circle_outlined, color: Color(0xFFF87171), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exp.category.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prop?.name ?? ""} • ${DateFormatter.formatDate(exp.date)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    if (exp.note != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        exp.note!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(exp.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF87171)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.cardDark,
                                          title: const Text('Delete Expense?'),
                                          content: Text('Delete expense of ₹${exp.amount}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(expensesProvider.notifier).deleteExpense(exp.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
