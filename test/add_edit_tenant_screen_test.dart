import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/tenants/presentation/add_edit_tenant_screen.dart';

void main() {
  testWidgets('AddEditTenantScreen renders with Sharma Niwas initialPropertyId without crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: AddEditTenantScreen(initialPropertyId: 'prop_sharma_complex'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Building (बिल्डिंग) *'), findsOneWidget);
  });
}

