import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatape/features/auth/data/auth_repository.dart';
import 'package:khatape/features/properties/data/property_repository.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/properties/domain/models/unit.dart';
import 'package:khatape/features/tenants/data/tenant_repository.dart';
import 'package:khatape/features/tenants/domain/models/tenant.dart';
import 'package:khatape/features/rent/data/rent_repository.dart';
import 'package:khatape/features/expenses/data/expense_repository.dart';
import 'package:khatape/core/utils/date_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Adding a building generates initial rooms correctly', () async {
    final propertiesNotifier = container.read(propertiesProvider.notifier);

    await propertiesNotifier.addProperty(
      name: 'Test Residency',
      type: PropertyType.building,
      address: '123 Test Street',
      city: 'Delhi',
      initialRoomCount: 5,
      defaultRoomRent: 5000,
      defaultRoomDeposit: 10000,
      startingRoomNumber: 101,
    );

    final properties = container.read(propertiesProvider);
    final testProp = properties.firstWhere((p) => p.name == 'Test Residency');

    expect(testProp.units.length, 5);
    expect(testProp.units.first.unitName, 'Room 101');
    expect(testProp.units.first.monthlyRent, 5000);
    expect(testProp.units.first.status, UnitStatus.vacant);
  });

  test('Adding a tenant auto-marks room as occupied and creates rent ledger entry', () async {
    final propertiesNotifier = container.read(propertiesProvider.notifier);
    final tenantsNotifier = container.read(tenantsProvider.notifier);

    // 1. Add building
    await propertiesNotifier.addProperty(
      name: 'Gokul Dham',
      type: PropertyType.building,
      address: 'Sector 5',
      city: 'Mumbai',
      initialRoomCount: 2,
      defaultRoomRent: 6000,
      defaultRoomDeposit: 12000,
      startingRoomNumber: 201,
    );

    final prop = container.read(propertiesProvider).firstWhere((p) => p.name == 'Gokul Dham');
    final targetRoom = prop.units.first;

    // 2. Add tenant to targetRoom moving in on the 1st of month
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final newTenant = Tenant(
      id: 'tenant_jethalal',
      name: 'Jethalal Gada',
      phone: '9820011223',
      propertyId: prop.id,
      unitId: targetRoom.id,
      moveInDate: firstOfMonth,
      monthlyRent: 6000,
      rentDueDay: 5,
      securityDeposit: 12000,
      isActive: true,
    );

    await tenantsNotifier.addTenant(newTenant);

    // 3. Verify room is occupied
    final updatedProp = container.read(propertiesProvider).firstWhere((p) => p.id == prop.id);
    final updatedRoom = updatedProp.units.firstWhere((u) => u.id == targetRoom.id);
    expect(updatedRoom.status, UnitStatus.occupied);

    // 4. Verify rent ledger entry exists for this tenant with full rent
    final currentMonthKey = DateFormatter.toMonthKey(now);
    final rentEntries = container.read(rentLedgerProvider);
    final tenantEntry = rentEntries.where((e) => e.tenantId == 'tenant_jethalal' && e.month == currentMonthKey).firstOrNull;

    expect(tenantEntry, isNotNull);
    expect(tenantEntry!.expectedAmount, 6000);
    expect(tenantEntry.propertyId, prop.id);
    expect(tenantEntry.unitId, targetRoom.id);
  });

  test('Deleting a tenant sets unit to vacant and cascades deletion of rent entries', () async {
    final propertiesNotifier = container.read(propertiesProvider.notifier);
    final tenantsNotifier = container.read(tenantsProvider.notifier);

    await propertiesNotifier.addProperty(
      name: 'Anand Villa',
      type: PropertyType.building,
      address: 'Lane 4',
      city: 'Delhi',
      initialRoomCount: 1,
      defaultRoomRent: 4000,
      defaultRoomDeposit: 8000,
      startingRoomNumber: 301,
    );

    final prop = container.read(propertiesProvider).firstWhere((p) => p.name == 'Anand Villa');
    final room = prop.units.first;

    final tenant = Tenant(
      id: 'tenant_anand',
      name: 'Anand Kumar',
      phone: '9811112222',
      propertyId: prop.id,
      unitId: room.id,
      moveInDate: DateTime.now(),
      monthlyRent: 4000,
      rentDueDay: 5,
      securityDeposit: 8000,
      isActive: true,
    );

    await tenantsNotifier.addTenant(tenant);

    // Verify tenant exists and room is occupied
    expect(container.read(tenantsProvider).any((t) => t.id == 'tenant_anand'), isTrue);
    expect(container.read(rentLedgerProvider).any((e) => e.tenantId == 'tenant_anand'), isTrue);

    // Delete tenant
    await tenantsNotifier.deleteTenant('tenant_anand');

    // Tenant is gone
    expect(container.read(tenantsProvider).any((t) => t.id == 'tenant_anand'), isFalse);

    // Room is back to vacant
    final propAfter = container.read(propertiesProvider).firstWhere((p) => p.id == prop.id);
    expect(propAfter.units.first.status, UnitStatus.vacant);

    // Rent entries for this tenant are removed (no orphan/ghost records)
    final entriesAfter = container.read(rentLedgerProvider);
    expect(entriesAfter.any((e) => e.tenantId == 'tenant_anand'), isFalse);
  });

  test('Deleting a building cascades deletion of tenants, rooms, and rent records', () async {
    final propertiesNotifier = container.read(propertiesProvider.notifier);
    final tenantsNotifier = container.read(tenantsProvider.notifier);

    await propertiesNotifier.addProperty(
      name: 'Building To Delete',
      type: PropertyType.building,
      address: 'Demolition Road',
      city: 'Delhi',
      initialRoomCount: 2,
      defaultRoomRent: 3000,
      defaultRoomDeposit: 6000,
      startingRoomNumber: 101,
    );

    final prop = container.read(propertiesProvider).firstWhere((p) => p.name == 'Building To Delete');

    final tenant = Tenant(
      id: 'temp_tenant',
      name: 'Temp Tenant',
      phone: '9000000000',
      propertyId: prop.id,
      unitId: prop.units.first.id,
      moveInDate: DateTime.now(),
      monthlyRent: 3000,
      rentDueDay: 5,
      securityDeposit: 6000,
      isActive: true,
    );

    await tenantsNotifier.addTenant(tenant);

    // Delete entire building
    await propertiesNotifier.deleteProperty(prop.id);

    // Property is deleted
    expect(container.read(propertiesProvider).any((p) => p.id == prop.id), isFalse);

    // Associated tenants are cascade-deleted
    expect(container.read(tenantsProvider).any((t) => t.propertyId == prop.id), isFalse);

    // Associated rent entries are cascade-deleted
    expect(container.read(rentLedgerProvider).any((e) => e.propertyId == prop.id), isFalse);
  });
}
