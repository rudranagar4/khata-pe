import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/widgets/khata_pe_brand.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/models/property.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/domain/models/tenant.dart';
import '../../settings/data/settings_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../data/rent_repository.dart';
import '../domain/models/payment.dart';
import '../domain/models/rent_entry.dart';
import '../domain/services/rent_calculator.dart';
import 'rent_entry_detail_sheet.dart';
import 'add_payment_dialog.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  RentStatus? _selectedStatusFilter;
  String? _selectedPropertyIdFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMonth = ref.read(selectedMonthProvider);
      ref.read(rentLedgerProvider.notifier).ensureMonthEntries(currentMonth);
    });
  }

  void _remindAllOverdue(List<RentEntry> overdueEntries) async {
    if (overdueEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No overdue tenants to remind for this month! 🎉')),
      );
      return;
    }

    final tenants = ref.read(tenantsProvider);
    final settings = ref.read(userSettingsProvider);
    final user = ref.read(currentUserProvider);
    final monthKey = ref.read(selectedMonthProvider);
    final monthName = DateFormatter.formatMonthYear(DateFormatter.fromMonthKey(monthKey));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Remind ${overdueEntries.length} Overdue Tenants?'),
        content: const Text(
          'This will prepare WhatsApp reminders for all tenants with outstanding balances.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Start Reminding'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final entry in overdueEntries) {
      final tenant = tenants.where((t) => t.id == entry.tenantId).firstOrNull;
      if (tenant == null) continue;
      final msg = WhatsAppService.buildMessage(
        template: settings.language == 'hi'
            ? settings.reminderTemplateHi
            : settings.reminderTemplateEn,
        tenantName: tenant.name,
        amountDue: entry.balanceDue,
        month: monthName,
        ownerName: user?.name ?? 'Anil',
      );
      await WhatsAppService.sendWhatsAppReminder(phone: tenant.phone, message: msg);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _quickExportExcel() async {
    final monthKey = ref.read(selectedMonthProvider);
    final properties = ref.read(propertiesProvider);
    final tenants = ref.read(tenantsProvider);
    final rentEntries = ref.read(rentLedgerProvider);
    final expenses = ref.read(expensesProvider);

    try {
      final exportProperties = _selectedPropertyIdFilter != null
          ? properties.where((p) => p.id == _selectedPropertyIdFilter).toList()
          : properties;

      final result = await ExcelExportService.generateMonthlyReport(
        monthKey: monthKey,
        properties: exportProperties,
        tenants: tenants,
        rentEntries: rentEntries,
        expenses: expenses,
      );

      await ExcelExportService.shareFile(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthKey = ref.watch(selectedMonthProvider);
    final monthDate = DateFormatter.fromMonthKey(currentMonthKey);
    final monthName = DateFormatter.formatMonthYear(monthDate);

    final rawEntries = ref.watch(currentMonthEntriesProvider);
    final properties = ref.watch(propertiesProvider);
    final tenants = ref.watch(tenantsProvider);

    // Filter out any orphaned entries for tenants that no longer exist
    final activeTenantIds = tenants.map((t) => t.id).toSet();
    final entries = rawEntries.where((e) => activeTenantIds.contains(e.tenantId)).toList();

    // Filter by selected building if specified
    final propertyFilteredEntries = _selectedPropertyIdFilter == null
        ? entries
        : entries.where((e) => e.propertyId == _selectedPropertyIdFilter).toList();

    final summary = RentCalculator.calculateSummary(propertyFilteredEntries);
    final overdueEntries = propertyFilteredEntries.where((e) => e.status == RentStatus.overdue).toList();

    final allPayments = propertyFilteredEntries.expand((e) => e.payments).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final cashPayments = allPayments.where((p) => p.mode == PaymentMode.cash).toList();
    final bankPayments = allPayments.where((p) => p.mode == PaymentMode.bank).toList();

    // Apply Status Filter
    final filteredEntries = _selectedStatusFilter == null
        ? propertyFilteredEntries
        : propertyFilteredEntries.where((e) {
            if (_selectedStatusFilter == RentStatus.overdue) {
              return e.status == RentStatus.overdue;
            } else if (_selectedStatusFilter == RentStatus.partiallyPaid) {
              return e.status == RentStatus.partiallyPaid;
            } else if (_selectedStatusFilter == RentStatus.paid) {
              return e.status == RentStatus.paid;
            }
            return e.status == _selectedStatusFilter;
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldDark,
        elevation: 0,
        title: const KhataPeBrand(),
        actions: [
          CircularTopActionButton(
            icon: Icons.notifications_none_rounded,
            hasBadge: overdueEntries.isNotEmpty,
            onTap: () => _remindAllOverdue(overdueEntries),
          ),
          const SizedBox(width: 8),
          CircularTopActionButton(
            icon: Icons.download_rounded,
            onTap: _quickExportExcel,
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          if (entries.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add properties and tenants first')),
            );
            return;
          }
          final pendingEntries = entries.where((e) => e.balanceDue > 0).toList();
          final target = pendingEntries.isNotEmpty ? pendingEntries.first : entries.first;
          AddPaymentDialog.show(context, target);
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Payment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardDark,
        onRefresh: () async {
          ref.read(rentLedgerProvider.notifier).ensureMonthEntries(currentMonthKey);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Month Selector Bar (Matching Image 1)
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.textSecondary),
                      onPressed: () {
                        final prev = DateFormatter.getPreviousMonth(currentMonthKey);
                        ref.read(selectedMonthProvider.notifier).state = prev;
                        ref.read(rentLedgerProvider.notifier).ensureMonthEntries(prev);
                      },
                    ),
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
                          final newKey = DateFormatter.toMonthKey(picked);
                          ref.read(selectedMonthProvider.notifier).state = newKey;
                          ref.read(rentLedgerProvider.notifier).ensureMonthEntries(newKey);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textSecondary),
                      onPressed: () {
                        final next = DateFormatter.getNextMonth(currentMonthKey);
                        ref.read(selectedMonthProvider.notifier).state = next;
                        ref.read(rentLedgerProvider.notifier).ensureMonthEntries(next);
                      },
                    ),
                  ],
                ),
              ),

              // Building Filter Chips Bar
              if (properties.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildBuildingFilterChip(
                        label: 'All Buildings (${properties.length})',
                        isSelected: _selectedPropertyIdFilter == null,
                        onTap: () => setState(() => _selectedPropertyIdFilter = null),
                      ),
                      ...properties.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildBuildingFilterChip(
                            label: p.name,
                            isSelected: _selectedPropertyIdFilter == p.id,
                            onTap: () => setState(() => _selectedPropertyIdFilter = p.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                const SizedBox(height: 14),
              ],

              // 2. Hero Collection Progress Card (Exact Gradient & Layout from Image 1)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0C3D26), // Deep emerald
                      Color(0xFF0F5434), // Rich forest green
                      Color(0xFF09311F),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E6B44), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collection Progress',
                          style: TextStyle(
                            color: Color(0xFFB4E0C9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${summary.collectionPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rounded Neon Green Progress Bar
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF072315),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (summary.collectionPercentage / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Received
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Received',
                                  style: TextStyle(color: Color(0xFFB4E0C9), fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(summary.totalReceived),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Expected Rent
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expected Rent',
                                  style: TextStyle(color: Color(0xFFB4E0C9), fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(summary.totalExpected),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Side-by-Side Metric Cards (Matching Image 1)
              Row(
                children: [
                  // Total Pending Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Total Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(summary.totalDue),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.totalTenants - summary.paidCount} tenants unpaid',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Overdue Rent Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_rounded,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Overdue Rent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(summary.totalOverdue),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF87171),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.overdueCount} tenants past due',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3.5 Payments Done via Cash & Bank Section
              _buildPaymentMethodsSection(
                context,
                summary,
                allPayments,
                cashPayments,
                bankPayments,
                entries,
                tenants,
                properties,
              ),

              const SizedBox(height: 18),

              // 4. Pill Filter Chips (Exact match to Image 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPillFilter('All (${entries.length})', null),
                    _buildPillFilter('Paid (${summary.paidCount})', RentStatus.paid),
                    _buildPillFilter('Partial (${summary.partialCount})', RentStatus.partiallyPaid),
                    _buildPillFilter('Overdue (${summary.overdueCount})', RentStatus.overdue),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. Tenant Rent Cards List (Exact match to Image 1)
              if (filteredEntries.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 12),
                      Text(
                        entries.isEmpty ? 'No rent entries for this month' : 'No entries match this filter',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    final tenant = tenants.where((t) => t.id == entry.tenantId).firstOrNull;
                    if (tenant == null) return const SizedBox.shrink();
                    final prop = properties.where((p) => p.id == entry.propertyId).firstOrNull;
                    final unit = prop?.units.where((u) => u.id == entry.unitId).firstOrNull;

                    // Choose avatar colors based on name index
                    final avatarBg = index % 3 == 0
                        ? const Color(0xFFC7EBD7) // Mint
                        : (index % 3 == 1 ? const Color(0xFFFDE68A) : const Color(0xFFDBEAFE));
                    final avatarFg = index % 3 == 0
                        ? const Color(0xFF0F5132)
                        : (index % 3 == 1 ? const Color(0xFF92400E) : const Color(0xFF1E40AF));

                    final isLate = entry.daysOverdue > 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark, width: 1),
                      ),
                      child: InkWell(
                        onTap: () => RentEntryDetailSheet.show(context, entry),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: avatarBg,
                                child: Text(
                                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                                  style: TextStyle(
                                    color: avatarFg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenant.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prop?.name ?? ""} • ${unit?.roomDisplayName ?? ""}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        children: [
                                          const TextSpan(text: 'Due: '),
                                          TextSpan(
                                            text: isLate
                                                ? '${DateFormatter.formatDate(entry.dueDate)} (${entry.daysOverdue}d late)'
                                                : DateFormatter.formatDate(entry.dueDate),
                                            style: TextStyle(
                                              color: isLate ? const Color(0xFFF87171) : AppColors.textSecondary,
                                              fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(entry.totalPayable),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (entry.balanceDue > 0 && entry.amountReceived > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bal: ${CurrencyFormatter.format(entry.balanceDue)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFFBBF24),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  _buildStatusBadge(entry.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillFilter(String label, RentStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatusFilter = isSelected ? null : status;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A) : AppColors.cardDarkElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : AppColors.borderDark,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RentStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case RentStatus.paid:
        bg = const Color(0xFF16A34A);
        fg = Colors.white;
        text = 'Paid';
        break;
      case RentStatus.partiallyPaid:
        bg = const Color(0xFFF59E0B);
        fg = Colors.black87;
        text = 'Partially Paid';
        break;
      case RentStatus.overdue:
        bg = const Color(0xFFEF4444);
        fg = Colors.white;
        text = 'Overdue';
        break;
      case RentStatus.due:
      case RentStatus.upcoming:
        bg = const Color(0xFF334155);
        fg = Colors.white70;
        text = status == RentStatus.due ? 'Due' : 'Upcoming';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(
    BuildContext context,
    MonthSummary summary,
    List<Payment> allPayments,
    List<Payment> cashPayments,
    List<Payment> bankPayments,
    List<RentEntry> entries,
    List<Tenant> tenants,
    List<Property> properties,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 16,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Payments Done (किए गए भुगतान)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: allPayments.isEmpty
                    ? null
                    : () => _showPaymentsHistorySheet(
                          context,
                          'All Recorded Payments',
                          allPayments,
                          entries,
                          tenants,
                          properties,
                        ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '${allPayments.length} Total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: allPayments.isNotEmpty
                              ? const Color(0xFF4ADE80)
                              : AppColors.textMuted,
                        ),
                      ),
                      if (allPayments.isNotEmpty) ...[
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF4ADE80),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two side-by-side cards: Cash and Bank
          Row(
            children: [
              // 1. Cash Card
              Expanded(
                child: InkWell(
                  onTap: cashPayments.isEmpty
                      ? null
                      : () => _showPaymentsHistorySheet(
                            context,
                            'Cash Payments (नकद भुगतान)',
                            cashPayments,
                            entries,
                            tenants,
                            properties,
                          ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10261A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cashPayments.isNotEmpty
                            ? const Color(0xFF1B613B)
                            : const Color(0xFF1A3828),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  size: 16,
                                  color: Color(0xFF4ADE80),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cash',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB4E0C9),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${summary.cashPaymentsCount} done',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4ADE80),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(summary.cashAmount),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${summary.cashPaymentsCount} ${summary.cashPaymentsCount == 1 ? "payment" : "payments"} in Cash',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF86A393),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Bank Card
              Expanded(
                child: InkWell(
                  onTap: bankPayments.isEmpty
                      ? null
                      : () => _showPaymentsHistorySheet(
                            context,
                            'Bank Payments (बैंक भुगतान)',
                            bankPayments,
                            entries,
                            tenants,
                            properties,
                          ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF112236),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: bankPayments.isNotEmpty
                            ? const Color(0xFF1E466F)
                            : const Color(0xFF19324D),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 16,
                                  color: Color(0xFF60A5FA),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Bank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFBFDBFE),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${summary.bankPaymentsCount} done',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF60A5FA),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(summary.bankAmount),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${summary.bankPaymentsCount} ${summary.bankPaymentsCount == 1 ? "payment" : "payments"} in Bank',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF849BB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentsHistorySheet(
    BuildContext context,
    String sheetTitle,
    List<Payment> payments,
    List<RentEntry> entries,
    List<Tenant> tenants,
    List<Property> properties,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            final totalAmt = payments.fold(0, (sum, p) => sum + p.amount);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheetTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${payments.length} payments • Total: ${CurrencyFormatter.format(totalAmt)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4ADE80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderDark, height: 1),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final p = payments[idx];
                        final entry = entries.where((e) => e.id == p.rentEntryId).firstOrNull;
                        final tenant = entry != null
                            ? tenants.where((t) => t.id == entry.tenantId).firstOrNull
                            : null;
                        final prop = entry != null
                            ? properties.where((pr) => pr.id == entry.propertyId).firstOrNull
                            : null;
                        final unit = prop?.units.where((u) => u.id == entry?.unitId).firstOrNull;

                        final isCash = p.mode == PaymentMode.cash;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF182230),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF263345), width: 1),
                          ),
                          child: Row(
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isCash
                                      ? const Color(0xFF132E20)
                                      : const Color(0xFF152A42),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCash ? Icons.payments_rounded : Icons.account_balance_rounded,
                                  color: isCash ? const Color(0xFF4ADE80) : const Color(0xFF60A5FA),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenant?.name ?? 'Tenant',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${prop?.name ?? "Building"} • ${unit?.roomDisplayName ?? "Room"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          DateFormatter.formatDate(p.date),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        if (p.receiptNo.isNotEmpty) ...[
                                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                          Text(
                                            p.receiptNo,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (p.referenceNo != null && p.referenceNo!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ref: ${p.referenceNo}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF93C5FD),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Amount & Mode Badge
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+ ${CurrencyFormatter.format(p.amount)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4ADE80),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCash
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                                          : const Color(0xFF2563EB).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isCash ? 'Cash (नकद)' : 'Bank (बैंक)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isCash ? const Color(0xFF4ADE80) : const Color(0xFF93C5FD),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBuildingFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16A34A) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isSelected ? const Color(0xFF22C55E) : AppColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
