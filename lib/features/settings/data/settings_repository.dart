import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/user_settings.dart';

class SettingsRepository {
  static const String _prefSettingsKey = 'khatape_settings';
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  UserSettings getSettings() {
    final raw = _prefs.getString(_prefSettingsKey);
    if (raw != null) {
      try {
        return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const UserSettings();
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _prefs.setString(_prefSettingsKey, jsonEncode(settings.toJson()));
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.getSettings());

  Future<void> updateSettings(UserSettings settings) async {
    state = settings;
    await _repo.saveSettings(settings);
  }

  Future<void> setLanguage(String lang) async {
    final updated = state.copyWith(language: lang);
    await updateSettings(updated);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  Future<void> setAppLock({required bool enabled, String? pin}) async {
    final updated = state.copyWith(
      appLockEnabled: enabled,
      biometricEnabled: enabled,
      pinCode: pin ?? state.pinCode,
    );
    await updateSettings(updated);
  }

  Future<void> updateReminderTemplates({
    String? enTemplate,
    String? hiTemplate,
  }) async {
    final updated = state.copyWith(
      reminderTemplateEn: enTemplate ?? state.reminderTemplateEn,
      reminderTemplateHi: hiTemplate ?? state.reminderTemplateHi,
    );
    await updateSettings(updated);
  }
}

final userSettingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});

