import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen does not contain Language or App Theme options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Language and App Theme options are removed
    expect(find.text('Language (भाषा)'), findsNothing);
    expect(find.text('App Theme'), findsNothing);
    expect(find.text('PREFERENCES & LOCALIZATION'), findsNothing);

    // Verify remaining essential settings options remain
    expect(find.text('App Lock (Biometric Unlock)'), findsOneWidget);
    expect(find.text('WhatsApp Reminder Templates'), findsOneWidget);
    expect(find.text('Property Expenses'), findsOneWidget);
  });
}
