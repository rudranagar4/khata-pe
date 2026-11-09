import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/excel_export_service.dart';
import '../../properties/data/property_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../rent/domain/services/rent_calculator.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late String _selectedMonth;
  String? _selectedPropertyId;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = ref.read(selectedMonthProvider);
  }

  void _exportExcel() async {
    setState(() => _isExporting = true);

    final properties = ref.read(propertiesProvider);
    final tenants = ref.read(tenantsProvider);
    final rentEntries = ref.read(rentLedgerProvider);
    final expenses = ref.read(expensesProvider);

    try {
      final result = await ExcelExportService.generateMonthlyReport(
        monthKey: _selectedMonth,
        properties: properties,
        tenants: tenants,
        rentEntries: rentEntries,
        expenses: expenses,
        selectedPropertyId: _selectedPropertyId,
      );

      if (!mounted) return;

      // Show success bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF133824),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Excel Report Ready!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  result.fileName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Includes 5 sheets: Summary, Rent Details, Pending List, Expenses, Net Income.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ExcelExportService.shareFile(result);
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share File (WhatsApp, Mail, Drive)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = ref.watch(propertiesProvider);
    final rentEntries = ref.watch(rentLedgerProvider);
    final expenses = ref.watch(expensesProvider);

    final monthDate = DateFormatter.fromMonthKey(_selectedMonth);
    final monthName = DateFormatter.formatMonthYear(monthDate);

    final monthRentEntries = _selectedPropertyId == null || _selectedPropertyId!.isEmpty
        ? rentEntries.where((e) => e.month == _selectedMonth).toList()
        : rentEntries
            .where((e) => e.month == _selectedMonth && e.propertyId == _selectedPropertyId)
            .toList();

    final monthExpenses = _selectedPropertyId == null || _selectedPropertyId!.isEmpty
        ? expenses
        : expenses.where((e) => e.propertyId == _selectedPropertyId).toList();

    final summary = RentCalculator.calculateSummary(monthRentEntries);
    final totalSpent = monthExpenses.fold(0, (sum, e) => sum + e.amount);
    final netProfit = summary.totalReceived - totalSpent;

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('Reports & Exports (रिपोर्ट्स)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Picker Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Report Month',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: monthDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() => _selectedMonth = DateFormatter.toMonthKey(picked));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF182230),
                        border: Border.all(color: AppColors.borderDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Color(0xFF4ADE80)),
                              const SizedBox(width: 10),
                              Text(
                                monthName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Building Filter
                  const Text(
                    'Building Filter (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPropertyId,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Buildings (सभी बिल्डिंग्स)'),
                      ),
                      ...properties.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (val) => setState(() => _selectedPropertyId = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2433),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report Summary Preview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${summary.collectionPercentage.toStringAsFixed(1)}% Collected',
                          style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPreviewRow('Expected Rent', CurrencyFormatter.format(summary.totalExpected)),
                  _buildPreviewRow('Total Received', CurrencyFormatter.format(summary.totalReceived), color: const Color(0xFF4ADE80)),
                  _buildPreviewRow('  • Cash Payments (${summary.cashPaymentsCount})', CurrencyFormatter.format(summary.cashAmount), color: const Color(0xFF86EFAC)),
                  _buildPreviewRow('  • Bank Payments (${summary.bankPaymentsCount})', CurrencyFormatter.format(summary.bankAmount), color: const Color(0xFF93C5FD)),
                  _buildPreviewRow('Total Pending / Due', CurrencyFormatter.format(summary.totalDue), color: const Color(0xFFFBBF24)),
                  _buildPreviewRow('Overdue Amount', CurrencyFormatter.format(summary.totalOverdue), color: const Color(0xFFF87171)),
                  _buildPreviewRow('Property Expenses', CurrencyFormatter.format(totalSpent)),
                  const Divider(color: AppColors.borderDark, height: 20),
                  _buildPreviewRow('Estimated Net Profit', CurrencyFormatter.format(netProfit), isBold: true, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Export Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isExporting ? null : _exportExcel,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.table_view_rounded),
                label: const Text(
                  'Generate 5-Sheet Excel Report (.xlsx)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Features Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What is included in the Excel file:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureBullet('1. Summary', 'Month totals, collection %, property-wise subtotals'),
                  _buildFeatureBullet('2. Rent Details', 'Tenant name, unit, due date, amount, mode, txn ID, notes'),
                  _buildFeatureBullet('3. Pending / Due List', 'Overdue tenants sorted by days late'),
                  _buildFeatureBullet('4. Expenses', 'All property repair and maintenance records'),
                  _buildFeatureBullet('5. Net Income', 'Collected rent minus expenses per building'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 14, color: color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF4ADE80)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.white),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
