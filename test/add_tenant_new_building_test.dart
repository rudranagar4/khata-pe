import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/data/property_repository.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/tenants/data/tenant_repository.dart';
import 'package:khatape/features/properties/presentation/property_detail_screen.dart';
import 'package:khatape/features/tenants/presentation/add_edit_tenant_screen.dart';

void main() {
  testWidgets('Flow A: Open PropertyDetailScreen for new building and tap Add Tenant', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Add a new building with 3 rooms
    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Sunrise Heights',
      type: PropertyType.building,
      address: 'Sector 62',
      city: 'Noida',
      initialRoomCount: 3,
      defaultRoomRent: 7000,
      defaultRoomDeposit: 14000,
      startingRoomNumber: 101,
    );

    final props = container.read(propertiesProvider);
    final newProp = props.firstWhere((p) => p.name == 'Sunrise Heights');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PropertyDetailScreen(propertyId: newProp.id),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify building name is visible
    expect(find.textContaining('Sunrise Heights'), findsAtLeastNWidgets(1));

    // Tap "Add Tenant" in the header
    final addTenantBtn = find.widgetWithText(TextButton, 'Tenant');
    expect(addTenantBtn, findsOneWidget);
    await tester.tap(addTenantBtn);
    await tester.pumpAndSettle();

    // Verify AddEditTenantScreen opened
    expect(find.text('Full Name *'), findsOneWidget);
  });

  testWidgets('Flow B: Add tenant to newly created building via AddEditTenantScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Add a new building with 2 rooms
    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Royal Palace',
      type: PropertyType.building,
      address: 'Civil Lines',
      city: 'Jaipur',
      initialRoomCount: 2,
      defaultRoomRent: 6000,
      defaultRoomDeposit: 12000,
      startingRoomNumber: 201,
    );

    final props = container.read(propertiesProvider);
    final royalProp = props.firstWhere((p) => p.name == 'Royal Palace');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AddEditTenantScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap building dropdown and select Royal Palace
    final buildingDropdown = find.byType(DropdownButtonFormField<String>).first;
    await tester.tap(buildingDropdown);
    await tester.pumpAndSettle();

    final royalOption = find.text('Royal Palace').last;
    await tester.tap(royalOption);
    await tester.pumpAndSettle();

    // Fill tenant details
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Ramesh Kumar'), 'Vikram Singh');
    await tester.enterText(find.widgetWithText(TextFormField, '9876543210'), '9876501234');

    // Tap Save button
    final saveBtn = find.widgetWithText(ElevatedButton, 'Add Tenant (किरायेदार जोड़ें)');
    expect(saveBtn, findsOneWidget);
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify tenant was added to container
    final tenants = container.read(tenantsProvider);
    expect(tenants.any((t) => t.name == 'Vikram Singh' && t.propertyId == royalProp.id), isTrue);
  });
}
