import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_auth_service.dart';
import '../data/auth_repository.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String? _error;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final success = await LocalAuthService.authenticate(
        reason: 'Scan your fingerprint to unlock Khata Pe',
      );
      if (success && mounted) {
        context.go('/home');
      } else if (mounted) {
        setState(() {
          _error = 'Biometric authentication cancelled or not recognized.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Biometric sensor error. Please tap to retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Biometric pulse container
              GestureDetector(
                onTap: _tryBiometric,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 54,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Khata Pe is Locked',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Touch fingerprint sensor or use biometrics to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.statusOverdue, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.statusOverdue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isAuthenticating ? null : _tryBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
                  label: _isAuthenticating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Unlock with Biometrics (बायोमेट्रिक से खोलें)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  ref.read(currentUserProvider.notifier).state = null;
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text(
                  'Sign In with Another Account',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
