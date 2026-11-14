import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../../auth/data/auth_repository.dart';
import '../data/settings_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/models/property.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/domain/models/tenant.dart';
import '../../rent/data/rent_repository.dart';
import '../../rent/domain/models/rent_entry.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/models/expense.dart';
import 'profile_screen.dart';
import 'reminder_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(userSettingsProvider);

    void syncWithFirebase() async {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Syncing data with Firebase Firestore...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final properties = ref.read(propertiesProvider);
      final tenants = ref.read(tenantsProvider);
      final rentEntries = ref.read(rentLedgerProvider);
      final expenses = ref.read(expensesProvider);

      if (user != null) {
        FirebaseSyncService.setActiveUser(user.id);
      }

      // 1. Push all local records to Firebase
      final count = await FirebaseSyncService.pushAllLocalData(
        properties: properties.map((p) => p.toJson()).toList(),
        tenants: tenants.map((t) => t.toJson()).toList(),
        rentEntries: rentEntries.map((r) => r.toJson()).toList(),
        expenses: expenses.map((e) => e.toJson()).toList(),
      );

      // 2. Fetch latest records from Firebase
      try {
        final cloudProps = await FirebaseSyncService.fetchAll('properties');
        if (cloudProps.isNotEmpty) {
          final props = cloudProps.map((d) => Property.fromJson(d)).toList();
          await ref.read(propertiesProvider.notifier).loadFromCloud(props);
        }

        final cloudTenants = await FirebaseSyncService.fetchAll('tenants');
        if (cloudTenants.isNotEmpty) {
          final tens = cloudTenants.map((d) => Tenant.fromJson(d)).toList();
          await ref.read(tenantsProvider.notifier).loadFromCloud(tens);
        }

        final cloudRent = await FirebaseSyncService.fetchAll('rent_entries');
        if (cloudRent.isNotEmpty) {
          final entries = cloudRent.map((d) => RentEntry.fromJson(d)).toList();
          await ref.read(rentLedgerProvider.notifier).loadFromCloud(entries);
        }

        final cloudExpenses = await FirebaseSyncService.fetchAll('expenses');
        if (cloudExpenses.isNotEmpty) {
          final exps = cloudExpenses.map((d) => Expense.fromJson(d)).toList();
          await ref.read(expensesProvider.notifier).loadFromCloud(exps);
        }
      } catch (e) {
        debugPrint('Cloud sync pull error: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              FirebaseSyncService.isInitialized
                  ? 'Cloud sync complete! ($count items verified)'
                  : 'Data saved locally. Connect to Firebase for cloud sync.',
            ),
          ),
        );
      }
    }

    void exportAllDataBackup() async {
      final properties = ref.read(propertiesProvider);
      final tenants = ref.read(tenantsProvider);
      final rentEntries = ref.read(rentLedgerProvider);
      final expenses = ref.read(expensesProvider);

      final backup = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'user': user?.toJson(),
        'properties': properties.map((p) => p.toJson()).toList(),
        'tenants': tenants.map((t) => t.toJson()).toList(),
        'rentEntries': rentEntries.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
      };

      final jsonStr = jsonEncode(backup);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/KhataPe_Full_Backup.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Khata Pe Data Backup',
        text: 'Khata Pe Full Data Backup (JSON)',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('Settings (सेटिंग्स)'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profile Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF16A34A).withOpacity(0.2),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'L',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                ),
              ),
              title: Text(
                user?.name ?? 'Anil',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
              ),
              subtitle: Text(
                '+91 ${user?.phone ?? ""}\n${user?.upiId ?? "UPI ID not set"}',
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.edit_outlined, color: Color(0xFF4ADE80)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeader(title: 'SECURITY & REMINDERS'),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded, color: Color(0xFF4ADE80)),
                  title: const Text('App Lock (Biometric Unlock)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Require fingerprint to open app', style: TextStyle(color: AppColors.textSecondary)),
                  value: settings.appLockEnabled,
                  activeColor: const Color(0xFF16A34A),
                  onChanged: (val) {
                    ref.read(userSettingsProvider.notifier).setAppLock(enabled: val);
                  },
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                  title: const Text('WhatsApp Reminder Templates', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Customize messages sent to tenants', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReminderSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeader(title: 'DATA & BACKUP'),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: Color(0xFF38BDF8)),
                  title: const Text('Sync with Firebase Cloud', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Back up & sync data with your online account', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8)),
                  onTap: syncWithFirebase,
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFFFBBF24)),
                  title: const Text('Property Expenses', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Track maintenance, repairs, & taxes', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/expenses'),
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF4ADE80)),
                  title: const Text('Export Full Backup (JSON)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Download all properties, tenants, & payments', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.file_download_outlined, color: AppColors.textSecondary),
                  onTap: exportAllDataBackup,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const _SectionHeader(title: 'ACCOUNT'),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardDark,
                        title: const Text('Sign Out?'),
                        content: const Text('Are you sure you want to sign out from Khata Pe?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.read(currentUserProvider.notifier).state = null;
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: AppColors.statusOverdue),
                  title: const Text('Delete Account & Data', style: TextStyle(color: AppColors.statusOverdue)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.cardDark,
                        title: const Text('Delete All Data?'),
                        content: const Text(
                          'This will permanently delete all properties, units, tenants, and payment records from this device.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authRepositoryProvider).deleteAccount();
                      ref.read(currentUserProvider.notifier).state = null;
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Khata Pe v1.0.0+1 • Made with ❤️ for Indian Landlords',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
