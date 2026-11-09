import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_auth_service.dart';
import '../../settings/data/settings_repository.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final success = await LocalAuthService.authenticate(
      reason: 'Unlock Khata Pe to view your rent ledger',
    );
    if (success && mounted) {
      context.go('/home');
    }
  }

  void _verifyPin() {
    final settings = ref.read(userSettingsProvider);
    final enteredPin = _pinController.text.trim();
    if (settings.pinCode != null && settings.pinCode!.isNotEmpty) {
      if (enteredPin == settings.pinCode) {
        context.go('/home');
      } else {
        setState(() => _error = 'Incorrect PIN. Please try again.');
      }
    } else {
      context.go('/home');
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(height: 24),
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
                'Authenticate with fingerprint or PIN to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 36),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF182230),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF263345)),
                ),
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 16, color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: '••••',
                    counterText: '',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _verifyPin,
                  child: const Text('Unlock with PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4ADE80),
                  side: const BorderSide(color: Color(0xFF4ADE80)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Use Biometrics / Fingerprint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
