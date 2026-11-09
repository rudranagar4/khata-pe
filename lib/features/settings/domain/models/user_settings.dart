import 'package:flutter/material.dart';

class UserSettings {
  final String language; // 'en' or 'hi'
  final ThemeMode themeMode;
  final bool appLockEnabled;
  final bool biometricEnabled;
  final String? pinCode;
  final String reminderTemplateEn;
  final String reminderTemplateHi;
  final int reminderDaysBeforeDue;
  final bool remindOnDueDate;
  final int remindDaysAfterOverdue;

  const UserSettings({
    this.language = 'en',
    this.themeMode = ThemeMode.system,
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.pinCode,
    this.reminderTemplateEn =
        'Namaste {tenantName} ji, your rent of {amount} for {month} is pending. Please send it soon. — {ownerName}',
    this.reminderTemplateHi =
        'नमस्ते {tenantName} जी, आपका {month} का किराया {amount} बाकी है। कृपया जल्द भेज दें। — {ownerName}',
    this.reminderDaysBeforeDue = 2,
    this.remindOnDueDate = true,
    this.remindDaysAfterOverdue = 3,
  });

  UserSettings copyWith({
    String? language,
    ThemeMode? themeMode,
    bool? appLockEnabled,
    bool? biometricEnabled,
    String? pinCode,
    String? reminderTemplateEn,
    String? reminderTemplateHi,
    int? reminderDaysBeforeDue,
    bool? remindOnDueDate,
    int? remindDaysAfterOverdue,
  }) {
    return UserSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinCode: pinCode ?? this.pinCode,
      reminderTemplateEn: reminderTemplateEn ?? this.reminderTemplateEn,
      reminderTemplateHi: reminderTemplateHi ?? this.reminderTemplateHi,
      reminderDaysBeforeDue: reminderDaysBeforeDue ?? this.reminderDaysBeforeDue,
      remindOnDueDate: remindOnDueDate ?? this.remindOnDueDate,
      remindDaysAfterOverdue: remindDaysAfterOverdue ?? this.remindDaysAfterOverdue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'themeMode': themeMode.name,
      'appLockEnabled': appLockEnabled,
      'biometricEnabled': biometricEnabled,
      'pinCode': pinCode,
      'reminderTemplateEn': reminderTemplateEn,
      'reminderTemplateHi': reminderTemplateHi,
      'reminderDaysBeforeDue': reminderDaysBeforeDue,
      'remindOnDueDate': remindOnDueDate,
      'remindDaysAfterOverdue': remindDaysAfterOverdue,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      language: json['language'] as String? ?? 'en',
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      pinCode: json['pinCode'] as String?,
      reminderTemplateEn: json['reminderTemplateEn'] as String? ??
          'Namaste {tenantName} ji, your rent of {amount} for {month} is pending. Please send it soon. — {ownerName}',
      reminderTemplateHi: json['reminderTemplateHi'] as String? ??
          'नमस्ते {tenantName} जी, आपका {month} का किराया {amount} बाकी है। कृपया जल्द भेज दें। — {ownerName}',
      reminderDaysBeforeDue: (json['reminderDaysBeforeDue'] as num?)?.toInt() ?? 2,
      remindOnDueDate: json['remindOnDueDate'] as bool? ?? true,
      remindDaysAfterOverdue: (json['remindDaysAfterOverdue'] as num?)?.toInt() ?? 3,
    );
  }
}

