import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../properties/data/property_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../data/rent_repository.dart';
import '../domain/models/payment.dart';
import '../domain/models/rent_entry.dart';

class AddPaymentDialog extends ConsumerStatefulWidget {
  final RentEntry entry;

  const AddPaymentDialog({super.key, required this.entry});

  static Future<void> show(BuildContext context, RentEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentDialog(entry: entry),
    );
  }

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  late final TextEditingController _amountController;
  final _refController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PaymentMode _selectedMode = PaymentMode.cash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.entry.balanceDue > 0
        ? widget.entry.balanceDue
        : widget.entry.totalPayable;
    _amountController = TextEditingController(text: initialAmount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
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

    setState(() => _isSaving = true);

    try {
      await ref.read(rentLedgerProvider.notifier).recordPayment(
            rentEntryId: widget.entry.id,
            amount: amount,
            date: _selectedDate,
            mode: _selectedMode,
            referenceNo: _refController.text.trim().isNotEmpty
                ? _refController.text.trim()
                : null,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text('Payment of ₹$amount recorded successfully!'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final tenants = ref.watch(tenantsProvider);
    final properties = ref.watch(propertiesProvider);
    final tenant = tenants.where((t) => t.id == widget.entry.tenantId).firstOrNull;
    final property = properties.where((p) => p.id == widget.entry.propertyId).firstOrNull;
    final unit = property?.units.where((u) => u.id == widget.entry.unitId).firstOrNull;
    final roomLabel = unit != null ? unit.roomDisplayName : 'Room';
    final tenantName = tenant != null ? tenant.name : '';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131A24), // Dark background matching Image 2
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: 24 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header (Credit card icon + Title + Subtitle + Close button)
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A), // Emerald green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Rent Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$roomLabel • ${property?.name ?? "Building"} ($tenantName)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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

            const SizedBox(height: 22),

            // Amount Received (₹) *
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                children: [
                  TextSpan(text: 'Amount Received (₹) '),
                  TextSpan(text: '*', style: TextStyle(color: Color(0xFF22C55E))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF263345), width: 1),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  hintText: 'Enter amount',
                  hintStyle: const TextStyle(color: Color(0xFF5D6F85), fontSize: 15),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8C9EB5)),
                    onPressed: () => _amountController.clear(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Date Received
            const Text(
              'Date Received',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF182230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF263345), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF8C9EB5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormatter.formatDate(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF8C9EB5)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Payment Mode (Only Cash and Bank)
            const Text(
              'Payment Mode (भुगतान का माध्यम)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModePill(PaymentMode.cash, Icons.payments_rounded, 'Cash (नकद)'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModePill(PaymentMode.bank, Icons.account_balance_rounded, 'Bank (बैंक)'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Bank Ref / UTR / Txn ID (Optional)
            const Text(
              'Bank Ref / UTR / Txn ID (Optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF263345), width: 1),
              ),
              child: TextField(
                controller: _refController,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: Icon(Icons.link_rounded, size: 18, color: Color(0xFF8C9EB5)),
                  hintText: 'Enter Bank Ref / UTR / Txn ID',
                  hintStyle: TextStyle(color: Color(0xFF5D6F85), fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Note / Remarks (Optional)
            const Text(
              'Note / Remarks (Optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF263345), width: 1),
              ),
              child: TextField(
                controller: _noteController,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF8C9EB5)),
                  hintText: 'Add a note (e.g. Paid in cash at house)',
                  hintStyle: TextStyle(color: Color(0xFF5D6F85), fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Payment Button (Matching Image 2)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // Emerald green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
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
                          Text(
                            'Confirm Payment (भुगतान दर्ज करें)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(PaymentMode mode, IconData icon, String label) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF182230),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF263345),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ] else ...[
              Icon(icon, size: 16, color: const Color(0xFF8C9EB5)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF8C9EB5),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_right_rounded, size: 18, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
