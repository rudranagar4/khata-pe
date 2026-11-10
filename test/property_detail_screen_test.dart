import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/presentation/property_detail_screen.dart';

void main() {
  testWidgets('PropertyDetailScreen renders Sharma Niwas correctly without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: PropertyDetailScreen(propertyId: 'prop_sharma_complex'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Sharma Niwas'), findsAtLeastNWidgets(1));
    expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
  });
}
