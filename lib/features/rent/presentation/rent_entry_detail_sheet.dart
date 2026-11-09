import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/pdf_receipt_service.dart';
import '../../properties/data/property_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../data/rent_repository.dart';
import '../domain/models/rent_entry.dart';
import 'add_payment_dialog.dart';

class RentEntryDetailSheet extends ConsumerWidget {
  final RentEntry entry;

  const RentEntryDetailSheet({super.key, required this.entry});

  static Future<void> show(BuildContext context, RentEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RentEntryDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntries = ref.watch(rentLedgerProvider);
    final currentEntry = allEntries.firstWhere((e) => e.id == entry.id, orElse: () => entry);

    final tenants = ref.watch(tenantsProvider);
    final properties = ref.watch(propertiesProvider);
    final settings = ref.watch(userSettingsProvider);
    final user = ref.watch(currentUserProvider);

    final tenant = tenants.where((t) => t.id == currentEntry.tenantId).firstOrNull;
    final property = properties.where((p) => p.id == currentEntry.propertyId).firstOrNull;
    final unit = property?.units.where((u) => u.id == currentEntry.unitId).firstOrNull;

    final tenantName = tenant?.name ?? 'Unknown Tenant';
    final tenantPhone = tenant?.phone ?? '';

    final monthDate = DateFormatter.fromMonthKey(currentEntry.month);
    final monthName = DateFormatter.formatMonthYear(monthDate);

    final reminderMessage = WhatsAppService.buildMessage(
      template: settings.language == 'hi'
          ? settings.reminderTemplateHi
          : settings.reminderTemplateEn,
      tenantName: tenantName,
      amountDue: currentEntry.balanceDue > 0 ? currentEntry.balanceDue : currentEntry.totalPayable,
      month: monthName,
      ownerName: user?.name ?? 'Anil',
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Header info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFC7EBD7),
                  child: Text(
                    tenantName.isNotEmpty ? tenantName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: Color(0xFF0F5132),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${property?.name ?? ""} • ${unit?.roomDisplayName ?? ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: currentEntry.status == RentStatus.paid
                        ? const Color(0xFF16A34A)
                        : (currentEntry.status == RentStatus.partiallyPaid
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentEntry.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Financial Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF182230),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF263345)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Month', monthName),
                  _buildSummaryRow(
                    'Due Date',
                    DateFormatter.formatDate(currentEntry.dueDate),
                    textColor: currentEntry.daysOverdue > 0 ? const Color(0xFFF87171) : null,
                  ),
                  _buildSummaryRow('Base Monthly Rent', CurrencyFormatter.format(currentEntry.expectedAmount)),
                  if (currentEntry.extraCharges > 0)
                    _buildSummaryRow(
                      'Utilities / Late Fee',
                      '+ ${CurrencyFormatter.format(currentEntry.extraCharges)}',
                      subtitle: currentEntry.extraChargesNote,
                    ),
                  if (currentEntry.advanceCreditApplied > 0)
                    _buildSummaryRow(
                      'Advance Credit Applied',
                      '- ${CurrencyFormatter.format(currentEntry.advanceCreditApplied)}',
                      textColor: const Color(0xFF4ADE80),
                    ),
                  const Divider(color: Color(0xFF263345), height: 20),
                  _buildSummaryRow(
                    'Total Payable',
                    CurrencyFormatter.format(currentEntry.totalPayable),
                    isBold: true,
                  ),
                  _buildSummaryRow(
                    'Amount Received',
                    CurrencyFormatter.format(currentEntry.totalCollected),
                    textColor: const Color(0xFF4ADE80),
                    isBold: true,
                  ),
                  _buildSummaryRow(
                    'Balance Due',
                    CurrencyFormatter.format(currentEntry.balanceDue),
                    textColor: currentEntry.balanceDue > 0 ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      AddPaymentDialog.show(context, currentEntry);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text('Add Payment'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: tenantPhone.isNotEmpty
                        ? () async {
                            await WhatsAppService.sendWhatsAppReminder(
                              phone: tenantPhone,
                              message: reminderMessage,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    onPressed: tenantPhone.isNotEmpty ? () => WhatsAppService.makePhoneCall(tenantPhone) : null,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    onPressed: tenantPhone.isNotEmpty
                        ? () => WhatsAppService.sendSms(
                              phone: tenantPhone,
                              message: reminderMessage,
                            )
                        : null,
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    label: const Text('SMS'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    onPressed: tenant != null
                        ? () {
                            Navigator.pop(context);
                            context.push('/tenant-detail/${tenant.id}');
                          }
                        : null,
                    icon: const Icon(Icons.person_search_outlined, size: 18),
                    label: const Text('Profile'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Payment History for this month
            if (currentEntry.payments.isNotEmpty) ...[
              const Text(
                'Payments for this Month',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...currentEntry.payments.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182230),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF263345)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.format(p.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            Text(
                              '${DateFormatter.formatDate(p.date)} • ${p.mode.displayName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Receipt',
                        icon: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                        onPressed: tenant != null
                            ? () {
                                PdfReceiptService.printOrShareReceipt(
                                  payment: p,
                                  rentEntry: currentEntry,
                                  tenant: tenant,
                                  property: property,
                                  unit: unit,
                                  ownerName: user?.name ?? 'Anil',
                                );
                              }
                            : null,
                      ),
                      IconButton(
                        tooltip: 'Undo',
                        icon: const Icon(Icons.undo_rounded, color: Colors.grey, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.cardDark,
                              title: const Text('Undo Payment?'),
                              content: Text('Remove payment of ₹${p.amount}? Balance will be restored.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Undo', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(rentLedgerProvider.notifier).undoPayment(currentEntry.id, p.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor, String? subtitle, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
