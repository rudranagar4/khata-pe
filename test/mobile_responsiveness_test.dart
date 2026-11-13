import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/presentation/property_detail_screen.dart';
import 'package:khatape/features/properties/data/property_repository.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/tenants/presentation/add_edit_tenant_screen.dart';
import 'package:khatape/features/tenants/data/tenant_repository.dart';

void main() {
  testWidgets('Test PropertyDetailScreen on mobile size 360x800 with vacant rooms', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Sharma Niwas',
      type: PropertyType.building,
      address: 'Lane 1',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
    );

    final prop = container.read(propertiesProvider).first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PropertyDetailScreen(propertyId: prop.id),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Sharma Niwas'), findsWidgets);
    expect(find.textContaining('Vacant'), findsWidgets);

    // Scroll to and Tap on Vacant filter chip
    final vacantChip = find.textContaining('Vacant').first;
    await tester.ensureVisible(vacantChip);
    await tester.tap(vacantChip);
    await tester.pumpAndSettle();

    // Scroll to and tap on Add Tenant button on a vacant room
    final addTenantBtn = find.widgetWithText(ElevatedButton, 'Add Tenant').first;
    expect(addTenantBtn, findsOneWidget);
    await tester.ensureVisible(addTenantBtn);
    await tester.tap(addTenantBtn);
    await tester.pumpAndSettle();
  });

  testWidgets('Test AddEditTenantScreen on mobile size 360x800 with pointer gestures', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Sharma Niwas',
      type: PropertyType.building,
      address: 'Lane 1',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
    );

    final prop = container.read(propertiesProvider).first;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AddEditTenantScreen(initialPropertyId: prop.id),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Add Tenant'), findsWidgets);

    // Enter tenant details
    await tester.enterText(find.byType(TextFormField).first, 'Aman Verma');
    await tester.pumpAndSettle();

    // Tap save button
    final saveButton = find.widgetWithText(ElevatedButton, 'Add Tenant (किरायेदार जोड़ें)');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  });

  testWidgets('Test Brand New Building with 0 rooms and adding tenant seamlessly', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Create a brand new building with 0 rooms
    await container.read(propertiesProvider.notifier).addProperty(
      name: 'Green Heights',
      type: PropertyType.building,
      address: 'Sector 62',
      city: 'Noida',
      initialRoomCount: 0,
    );

    final newProp = container.read(propertiesProvider).firstWhere((p) => p.name == 'Green Heights');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PropertyDetailScreen(propertyId: newProp.id),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Green Heights'), findsWidgets);
    expect(find.text('No rooms added to this building yet'), findsOneWidget);

    // Tap on AppBar Add Tenant button
    final addTenantIcon = find.byIcon(Icons.person_add_alt_1_outlined).first;
    await tester.tap(addTenantIcon);
    await tester.pumpAndSettle();

    // Verify AddEditTenantScreen is shown with "No rooms in this building yet" and "Add Room"
    expect(find.text('No rooms in this building yet.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add Room'), findsOneWidget);

    // Tap "Add Room" button inside warning banner
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Room'));
    await tester.pumpAndSettle();

    // Dialog appears: Tap "Create Room"
    expect(find.text('Create Room'), findsOneWidget);
    await tester.tap(find.text('Create Room'));
    await tester.pumpAndSettle();

    // Now Room 1 is created and preselected!
    expect(find.textContaining('Room 1'), findsWidgets);

    // Fill tenant details
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Ramesh Kumar'), 'Vikram Singh');
    await tester.enterText(find.widgetWithText(TextFormField, '9876543210'), '9876501234');
    await tester.pumpAndSettle();

    // Save tenant
    final saveBtn = find.widgetWithText(ElevatedButton, 'Add Tenant (किरायेदार जोड़ें)');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify tenant is added in container
    final tenants = container.read(tenantsProvider);
    expect(tenants.any((t) => t.name == 'Vikram Singh' && t.propertyId == newProp.id), isTrue);
  });
}
