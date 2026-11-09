import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/services/pdf_receipt_service.dart';
import '../data/tenant_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../rent/domain/models/rent_entry.dart';
import '../../settings/data/settings_repository.dart';
import '../../auth/data/auth_repository.dart';
import 'add_edit_tenant_screen.dart';

class TenantDetailScreen extends ConsumerWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenants = ref.watch(tenantsProvider);
    final tenant = tenants.where((t) => t.id == tenantId).firstOrNull;

    if (tenant == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldDark,
        appBar: AppBar(),
        body: const Center(child: Text('Tenant not found', style: TextStyle(color: Colors.white))),
      );
    }

    final properties = ref.watch(propertiesProvider);
    final property = properties.where((p) => p.id == tenant.propertyId).firstOrNull;
    final unit = property?.units.where((u) => u.id == tenant.unitId).firstOrNull;

    final allRentEntries = ref.watch(rentLedgerProvider);
    final tenantEntries = allRentEntries.where((e) => e.tenantId == tenant.id).toList()
      ..sort((a, b) => b.month.compareTo(a.month));

    final settings = ref.watch(userSettingsProvider);
    final user = ref.watch(currentUserProvider);

    final totalPaid = tenantEntries.fold(0, (sum, e) => sum + e.totalCollected);
    final totalDue = tenantEntries.fold(0, (sum, e) => sum + e.balanceDue);

    void exportLedger() async {
      try {
        final result = await ExcelExportService.generateTenantLedgerReport(
          tenant: tenant,
          property: property,
          unit: unit,
          tenantEntries: tenantEntries,
        );
        await ExcelExportService.shareFile(result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export error: $e')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: Text(tenant.name),
        actions: [
          IconButton(
            tooltip: 'Export Ledger (Excel)',
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            onPressed: exportLedger,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTenantScreen(tenantToEdit: tenant),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFC7EBD7),
                        child: Text(
                          tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            color: Color(0xFF0F5132),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+91 ${tenant.phone}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tenant.isActive ? AppColors.statusPaidBg : const Color(0xFF1E2838),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tenant.isActive ? 'Active Tenant' : 'Moved Out',
                                style: TextStyle(
                                  color: tenant.isActive ? const Color(0xFF4ADE80) : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderDark, height: 1),
                  const SizedBox(height: 12),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: const Color(0xFF4ADE80),
                        onTap: () => WhatsAppService.makePhoneCall(tenant.phone),
                      ),
                      _buildQuickAction(
                        icon: Icons.chat_bubble_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () {
                          final msg = WhatsAppService.buildMessage(
                            template: settings.language == 'hi'
                                ? settings.reminderTemplateHi
                                : settings.reminderTemplateEn,
                            tenantName: tenant.name,
                            amountDue: totalDue,
                            month: 'this month',
                            ownerName: user?.name ?? 'Anil',
                          );
                          WhatsAppService.sendWhatsAppReminder(phone: tenant.phone, message: msg);
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.sms_rounded,
                        label: 'SMS',
                        color: const Color(0xFF38BDF8),
                        onTap: () => WhatsAppService.sendSms(phone: tenant.phone, message: 'Namaste ${tenant.name}'),
                      ),
                      _buildQuickAction(
                        icon: Icons.table_chart_rounded,
                        label: 'Excel',
                        color: AppColors.accent,
                        onTap: exportLedger,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rental & ID details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Building', property?.name ?? '—'),
                  _buildDetailRow('Room No.', unit?.roomDisplayName ?? '—'),
                  _buildDetailRow('Monthly Rent', CurrencyFormatter.format(tenant.monthlyRent)),
                  _buildDetailRow('Security Deposit', CurrencyFormatter.format(tenant.securityDeposit)),
                  _buildDetailRow('Rent Due Day', '${tenant.rentDueDay}th of each month'),
                  _buildDetailRow('Move-in Date', DateFormatter.formatDate(tenant.moveInDate)),
                  if (tenant.agreementEndDate != null)
                    _buildDetailRow('Agreement End', DateFormatter.formatDate(tenant.agreementEndDate!)),
                  if (tenant.idProofNumber != null)
                    _buildDetailRow(tenant.idProofType ?? "ID", tenant.idProofNumber!),
                  if (tenant.email != null) _buildDetailRow('Email', tenant.email!),
                  if (tenant.notes != null) _buildDetailRow('Notes', tenant.notes!),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dues & Collection Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Collected', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalPaid),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: AppColors.borderDark),
                  Column(
                    children: [
                      const Text('Current Due', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalDue),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: totalDue > 0 ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Ledger History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History (लेजर)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  onPressed: exportLedger,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Excel'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (tenantEntries.isEmpty) ...[
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No rent records yet', style: TextStyle(color: AppColors.textSecondary)))),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tenantEntries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = tenantEntries[index];
                  final monthDate = DateFormatter.fromMonthKey(entry.month);
                  final monthStr = DateFormatter.formatMonthYear(monthDate);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                monthStr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Expected: ${CurrencyFormatter.format(entry.totalPayable)} • Received: ${CurrencyFormatter.format(entry.totalCollected)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry.status == RentStatus.paid
                                ? const Color(0xFF16A34A)
                                : (entry.status == RentStatus.partiallyPaid ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.status.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (entry.payments.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                            onPressed: () {
                              PdfReceiptService.printOrShareReceipt(
                                payment: entry.payments.last,
                                rentEntry: entry,
                                tenant: tenant,
                                property: property,
                                unit: unit,
                                ownerName: user?.name ?? 'Anil',
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 28),

            // Move-out / Delete actions
            if (tenant.isActive) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFBBF24),
                    side: const BorderSide(color: Color(0xFFFBBF24)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Mark Tenant as Moved Out (कमरा खाली किया)'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardDark,
                        title: const Text('Mark as Moved Out?'),
                        content: Text(
                          'Mark ${tenant.name} as moved out? Unit will become Vacant, but rent history is safely retained.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                            child: const Text('Confirm Move-Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(tenantsProvider.notifier).markMovedOut(tenant.id, DateTime.now());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tenant marked as moved out. Unit is now vacant.')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.statusOverdue),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Tenant Record'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.cardDark,
                      title: const Text('Delete Tenant?'),
                      content: const Text('Are you sure you want to permanently delete this tenant?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(tenantsProvider.notifier).deleteTenant(tenant.id);
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
