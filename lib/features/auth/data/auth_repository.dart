import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
  Future<void> sendOtp(String phoneNumber);
  Future<UserProfile> verifyOtp(String phoneNumber, String otp, {String? name});
  Future<void> updateProfile(UserProfile profile);
  Future<void> signOut();
  Future<void> deleteAccount();
}

class LocalAuthRepository implements AuthRepository {
  static const String _prefUserKey = 'khatape_user_profile';
  static const String _prefOnboardedKey = 'khatape_onboarded';

  final SharedPreferences _prefs;
  UserProfile? _currentUser;

  LocalAuthRepository(this._prefs) {
    _loadUser();
  }

  void _loadUser() {
    final userJson = _prefs.getString(_prefUserKey);
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    } else {
      // Default landlord Anil
      _currentUser = UserProfile(
        id: 'owner_anil',
        name: 'Anil',
        phone: '9876543210',
        language: 'en',
        upiId: 'anil@okhdfcbank',
        createdAt: DateTime(2026, 1, 1),
      );
    }
  }

  bool get isOnboarded => _prefs.getBool(_prefOnboardedKey) ?? false;

  Future<void> setOnboarded(bool value) async {
    await _prefs.setBool(_prefOnboardedKey, value);
  }

  @override
  Stream<UserProfile?> get authStateChanges async* {
    yield _currentUser;
  }

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // Simulated OTP dispatch (in real Firebase, phone auth sends SMS)
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<UserProfile> verifyOtp(String phoneNumber, String otp, {String? name}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = UserProfile(
      id: 'owner_user_1',
      name: name != null && name.isNotEmpty ? name : 'Anil',
      phone: phoneNumber,
      language: 'en',
      upiId: 'anil@okhdfcbank',
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    await _prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
    await setOnboarded(true);
    return user;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _currentUser = profile;
    await _prefs.setString(_prefUserKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _prefs.remove(_prefUserKey);
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    await _prefs.clear();
  }
}

// Riverpod Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final authRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalAuthRepository(prefs);
});

final currentUserProvider = StateProvider<UserProfile?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.currentUser;
});

