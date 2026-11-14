import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/khata_pe_brand.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../data/auth_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../properties/domain/models/property.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/domain/models/tenant.dart';
import '../../rent/data/rent_repository.dart';
import '../../rent/domain/models/rent_entry.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/models/expense.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = 'Signing in...';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Restores all data from Firestore after a successful login.
  /// Silently falls back to local data if Firebase is unavailable.
  Future<void> _restoreFromCloud() async {
    if (!mounted) return;
    setState(() => _loadingMessage = 'Syncing your data from cloud...');

    try {
      // Properties
      final propertiesData = await FirebaseSyncService.fetchAll('properties');
      if (propertiesData.isNotEmpty && mounted) {
        final props = propertiesData
            .map((d) => Property.fromJson(d))
            .toList();
        await ref.read(propertiesProvider.notifier).loadFromCloud(props);
      }

      // Tenants
      final tenantsData = await FirebaseSyncService.fetchAll('tenants');
      if (tenantsData.isNotEmpty && mounted) {
        final tenants = tenantsData
            .map((d) => Tenant.fromJson(d))
            .toList();
        await ref.read(tenantsProvider.notifier).loadFromCloud(tenants);
      }

      // Rent entries
      final rentData = await FirebaseSyncService.fetchAll('rent_entries');
      if (rentData.isNotEmpty && mounted) {
        final entries = rentData
            .map((d) => RentEntry.fromJson(d))
            .toList();
        await ref.read(rentLedgerProvider.notifier).loadFromCloud(entries);
      }

      // Expenses
      final expenseData = await FirebaseSyncService.fetchAll('expenses');
      if (expenseData.isNotEmpty && mounted) {
        final expenses = expenseData
            .map((d) => Expense.fromJson(d))
            .toList();
        await ref.read(expensesProvider.notifier).loadFromCloud(expenses);
      }
    } catch (e) {
      // Silent failure — local data remains unchanged
      debugPrint('Cloud restore error: $e');
    }
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Signing in...';
      _errorMessage = null;
    });

    try {
      final user = await ref.read(authRepositoryProvider).loginWithUsername(username, password);
      FirebaseSyncService.setActiveUser(user.id);
      ref.read(currentUserProvider.notifier).state = user;
      await _restoreFromCloud();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleQuickDemoLogin() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Signing in...';
      _errorMessage = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).loginDemo();
      FirebaseSyncService.setActiveUser(user.id);
      ref.read(currentUserProvider.notifier).state = user;
      await _restoreFromCloud();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const KhataPeBrand(fontSize: 28, iconSize: 42),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Khata Pe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in with your secure credentials to manage your properties.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Username Field
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF182230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF263345)),
                ),
                child: TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    hintText: 'Enter your username',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF182230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF263345)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.statusOverdue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.statusOverdue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _loadingMessage,
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Sign In (लॉग इन)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Demo Login Button
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFBBF24),
                    side: const BorderSide(color: Color(0xFFFBBF24)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _handleQuickDemoLogin,
                  icon: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFFBBF24)),
                  label: const Text('Quick Demo Login (डेमो लॉगिन)'),
                ),
              ),

              const SizedBox(height: 36),
              const Center(
                child: Text(
                  'Your credentials are securely encrypted with SHA-256.\nData is protected with end-to-end security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
