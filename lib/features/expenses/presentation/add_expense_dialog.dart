import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../properties/data/property_repository.dart';
import '../data/expense_repository.dart';
import '../domain/models/expense.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddExpenseDialog(),
    );
  }

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedPropertyId;
  ExpenseCategory _selectedCategory = ExpenseCategory.repairs;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select property for this expense')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(expensesProvider.notifier).addExpense(
            propertyId: _selectedPropertyId!,
            category: _selectedCategory,
            amount: amount,
            date: _selectedDate,
            note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFF16A34A), content: Text('Expense of ₹$amount recorded!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_selectedPropertyId == null && properties.isNotEmpty) {
      _selectedPropertyId = properties.first.id;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Building Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C2533),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Property selector
            const Text('Building *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedPropertyId,
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(),
              items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (val) => setState(() => _selectedPropertyId = val),
            ),

            const SizedBox(height: 16),

            // Amount
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                children: [
                  TextSpan(text: 'Expense Amount (₹) '),
                  TextSpan(text: '*', style: TextStyle(color: Color(0xFF22C55E))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF263345), width: 1),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                    child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ),
                  hintText: 'Enter amount',
                  hintStyle: TextStyle(color: Color(0xFF5D6F85), fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category selector
            const Text('Expense Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF182230),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF263345)),
                    ),
                    child: Text(
                      cat.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Date picker
            const Text('Date of Expense', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF182230),
                  border: Border.all(color: const Color(0xFF263345)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF8C9EB5)),
                    const SizedBox(width: 10),
                    Text(DateFormatter.formatDate(_selectedDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            const Text('Description / Bill Note', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF263345)),
              ),
              child: TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF8C9EB5)),
                  hintText: 'e.g. Plumber labor + new water tap',
                  hintStyle: TextStyle(color: Color(0xFF5D6F85), fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check, size: 20, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Save Expense (खर्चा दर्ज करें)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
