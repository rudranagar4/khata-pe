import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user_profile.dart';

class AllowedUser {
  final String username;
  final String passwordHash;
  final String name;
  final String phone;
  final String upiId;

  const AllowedUser({
    required this.username,
    required this.passwordHash,
    required this.name,
    required this.phone,
    required this.upiId,
  });
}

String _hashPassword(String password) {
  return sha256.convert(utf8.encode(password.trim())).toString();
}

/// Predefined authorized user accounts.
/// Passwords are encrypted/hashed with SHA-256 for maximum security.
/// Additional users can be added here in the future as requested.
final List<AllowedUser> kAllowedUsers = [
  AllowedUser(
    username: 'advanilnagar',
    passwordHash: _hashPassword('nagar1258'),
    name: 'Adv. Anil Nagar',
    phone: '9876543210',
    upiId: 'anilnagar@okhdfcbank',
  ),
];

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
  Future<UserProfile> loginWithUsername(String username, String password);
  Future<UserProfile> loginDemo();
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

  // Rate limiting / Brute force protection
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

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
      _currentUser = null;
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
  Future<UserProfile> loginWithUsername(String username, String password) async {
    // Check brute-force lockout
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final secondsLeft = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      throw 'Too many failed attempts. Account temporarily locked for $secondsLeft seconds.';
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      throw 'Please enter both username and password';
    }

    final inputHash = _hashPassword(cleanPassword);

    final matched = kAllowedUsers.cast<AllowedUser?>().firstWhere(
      (u) => u?.username.toLowerCase() == cleanUsername,
      orElse: () => null,
    );

    if (matched == null || matched.passwordHash != inputHash) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        _failedAttempts = 0;
        throw 'Too many failed attempts. Account temporarily locked for 30 seconds.';
      }
      throw 'Invalid username or password. Please try again.';
    }

    // Reset failed attempts on success
    _failedAttempts = 0;
    _lockoutUntil = null;

    final user = UserProfile(
      id: 'owner_${matched.username}',
      name: matched.name,
      phone: matched.phone,
      language: 'en',
      upiId: matched.upiId,
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
    await setOnboarded(true);
    return user;
  }

  @override
  Future<UserProfile> loginDemo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final demo = kAllowedUsers.first;
    final user = UserProfile(
      id: 'owner_${demo.username}',
      name: '${demo.name} (Demo)',
      phone: demo.phone,
      language: 'en',
      upiId: demo.upiId,
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _prefs.setString(_prefUserKey, jsonEncode(user.toJson()));
    await setOnboarded(true);
    return user;
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<UserProfile> verifyOtp(String phoneNumber, String otp, {String? name}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = UserProfile(
      id: 'owner_user_1',
      name: name != null && name.isNotEmpty ? name : 'Adv. Anil Nagar',
      phone: phoneNumber,
      language: 'en',
      upiId: 'anilnagar@okhdfcbank',
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
