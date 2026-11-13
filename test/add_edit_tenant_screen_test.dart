import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/data/property_repository.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/tenants/presentation/add_edit_tenant_screen.dart';

void main() {
  testWidgets('AddEditTenantScreen renders with initialPropertyId without crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Test Niwas',
      type: PropertyType.building,
      address: 'Lane 1',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
    );

    final props = container.read(propertiesProvider);
    final prop = props.first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AddEditTenantScreen(initialPropertyId: prop.id),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Building (बिल्डिंग) *'), findsOneWidget);
  });
}
