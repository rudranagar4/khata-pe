import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/khata_pe_brand.dart';
import '../data/auth_repository.dart';
import '../../settings/data/settings_repository.dart';

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
