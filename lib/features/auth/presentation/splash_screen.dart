import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/khata_pe_brand.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../data/auth_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/models/property.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/domain/models/tenant.dart';
import '../../rent/data/rent_repository.dart';
import '../../rent/domain/models/rent_entry.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/models/expense.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final settings = ref.read(userSettingsProvider);

    if (authRepo.currentUser != null) {
      // User was previously logged in — restore cloud data in background
      // so reinstalling the app doesn't lose Firestore data
      _restoreFromCloud(); // fire-and-forget, don't await (non-blocking)

      if (settings.appLockEnabled) {
        context.go('/lock');
      } else {
        context.go('/home');
      }
    } else {
      if (authRepo.isOnboarded) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  /// Restores all Firestore data into local state silently.
  Future<void> _restoreFromCloud() async {
    try {
      final propertiesData = await FirebaseSyncService.fetchAll('properties');
      if (propertiesData.isNotEmpty && mounted) {
        final props = propertiesData.map((d) => Property.fromJson(d)).toList();
        ref.read(propertiesProvider.notifier).loadFromCloud(props);
      }

      final tenantsData = await FirebaseSyncService.fetchAll('tenants');
      if (tenantsData.isNotEmpty && mounted) {
        final tenants = tenantsData.map((d) => Tenant.fromJson(d)).toList();
        ref.read(tenantsProvider.notifier).loadFromCloud(tenants);
      }

      final rentData = await FirebaseSyncService.fetchAll('rent_entries');
      if (rentData.isNotEmpty && mounted) {
        final entries = rentData.map((d) => RentEntry.fromJson(d)).toList();
        ref.read(rentLedgerProvider.notifier).loadFromCloud(entries);
      }

      final expenseData = await FirebaseSyncService.fetchAll('expenses');
      if (expenseData.isNotEmpty && mounted) {
        final expenses = expenseData.map((d) => Expense.fromJson(d)).toList();
        ref.read(expensesProvider.notifier).loadFromCloud(expenses);
      }
    } catch (e) {
      debugPrint('Splash cloud restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KhataPeBrand(fontSize: 34, iconSize: 56),
            const SizedBox(height: 14),
            Text(
              'खाता पे — हर महीने का सही हिसाब',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
