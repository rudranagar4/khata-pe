import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _upiController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _upiController = TextEditingController(text: user?.upiId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        upiId: _upiController.text.trim().isNotEmpty ? _upiController.text.trim() : null,
      );
      await ref.read(authRepositoryProvider).updateProfile(updated);
      ref.read(currentUserProvider.notifier).state = updated;

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF16A34A), content: Text('Profile updated!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        title: const Text('Landlord Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF16A34A).withOpacity(0.2),
                child: const Icon(Icons.person, size: 54, color: Color(0xFF4ADE80)),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Owner Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'e.g. Anil'),
            ),

            const SizedBox(height: 18),

            const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '9876543210'),
            ),

            const SizedBox(height: 18),

            const Text('UPI ID (for payments & QR code)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 6),
            TextField(
              controller: _upiController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'e.g. rajesh@okhdfcbank'),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
