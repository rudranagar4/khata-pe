import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../auth/data/auth_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../domain/models/property.dart';
import '../domain/models/unit.dart';

class PropertyRepository {
  static const String _prefKey = 'khatape_properties';
  final SharedPreferences _prefs;

  PropertyRepository(this._prefs);

  List<Property> getProperties() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list.map((e) => Property.fromJson(e as Map<String, dynamic>)).toList();
        final seedProps = _getSeedProperties();
        bool updated = false;
        final result = List<Property>.from(loaded);
        for (final seed in seedProps) {
          final existingIndex = result.indexWhere((p) => p.id == seed.id);
          if (existingIndex == -1) {
            result.add(seed);
            updated = true;
          } else if (result[existingIndex].units.isEmpty && seed.units.isNotEmpty) {
            // Restore rooms if existing property had 0 rooms
            result[existingIndex] = result[existingIndex].copyWith(units: seed.units);
            updated = true;
          }
        }
        if (updated) {
          saveProperties(result);
        }
        return result;
      } catch (_) {}
    }
    final seed = _getSeedProperties();
    saveProperties(seed);
    return seed;
  }

  Future<void> saveProperties(List<Property> properties) async {
    final encoded = jsonEncode(properties.map((p) => p.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }

  List<Property> _getSeedProperties() {
    const propNew14Id = 'prop_new_14';
    const prop1Id = 'prop_sharma_complex';
    const prop2Id = 'prop_sai_commercial';

    return [
      Property(
        id: propNew14Id,
        name: 'NEW 14',
        type: PropertyType.building,
        address: 'Plot 14, Main Road, Near Market',
        city: 'Delhi',
        notes: 'NEW 14 Building — 14 Room Rental Ledger (Owner: Anil)',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        units: const [
          PropertyUnit(id: 'unit_new14_1', propertyId: propNew14Id, unitName: 'Room 1', floor: 'Ground Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_2', propertyId: propNew14Id, unitName: 'Room 2', floor: 'Ground Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_3', propertyId: propNew14Id, unitName: 'Room 3', floor: 'Ground Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_4', propertyId: propNew14Id, unitName: 'Room 4', floor: '1st Floor', monthlyRent: 2630, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_5', propertyId: propNew14Id, unitName: 'Room 5', floor: '1st Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_6', propertyId: propNew14Id, unitName: 'Room 6', floor: '1st Floor', monthlyRent: 2630, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_7', propertyId: propNew14Id, unitName: 'Room 7', floor: '1st Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_8', propertyId: propNew14Id, unitName: 'Room 8', floor: '2nd Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_9', propertyId: propNew14Id, unitName: 'Room 9', floor: '2nd Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_10', propertyId: propNew14Id, unitName: 'Room 10', floor: '2nd Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_11', propertyId: propNew14Id, unitName: 'Room 11', floor: '3rd Floor', monthlyRent: 2630, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_12', propertyId: propNew14Id, unitName: 'Room 12', floor: '3rd Floor', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_13', propertyId: propNew14Id, unitName: 'Room 13', floor: '3rd Floor', monthlyRent: 2630, securityDeposit: 5000, status: UnitStatus.occupied),
          PropertyUnit(id: 'unit_new14_14', propertyId: propNew14Id, unitName: 'Room 14', floor: 'Rooftop', monthlyRent: 2430, securityDeposit: 5000, status: UnitStatus.occupied),
        ],
      ),
      Property(
        id: prop1Id,
        name: 'Sharma Niwas (Building 2)',
        type: PropertyType.building,
        address: 'B-12, Sector 15, Near Metro',
        city: 'Noida',
        notes: '3-story residential building rented as individual rooms',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        units: [
          const PropertyUnit(
            id: 'unit_101',
            propertyId: prop1Id,
            unitName: 'Room 101',
            floor: '1st Floor',
            roomType: 'Single Room (1RK)',
            monthlyRent: 8500,
            securityDeposit: 17000,
            status: UnitStatus.occupied,
            areaSqFt: 220,
            meterNumber: 'M-101',
          ),
          const PropertyUnit(
            id: 'unit_102',
            propertyId: prop1Id,
            unitName: 'Room 102',
            floor: '1st Floor',
            roomType: 'Double Room (Attached Bath)',
            monthlyRent: 14000,
            securityDeposit: 28000,
            status: UnitStatus.occupied,
            areaSqFt: 350,
            meterNumber: 'M-102',
          ),
          const PropertyUnit(
            id: 'unit_103',
            propertyId: prop1Id,
            unitName: 'Room 103',
            floor: '1st Floor',
            roomType: 'Single Room',
            monthlyRent: 9000,
            securityDeposit: 18000,
            status: UnitStatus.vacant,
            areaSqFt: 220,
            meterNumber: 'M-103',
          ),
          const PropertyUnit(
            id: 'unit_104',
            propertyId: prop1Id,
            unitName: 'Room 104',
            floor: '1st Floor',
            roomType: 'Balcony Room',
            monthlyRent: 8500,
            securityDeposit: 17000,
            status: UnitStatus.vacant,
            areaSqFt: 240,
            meterNumber: 'M-104',
          ),
        ],
      ),
      Property(
        id: prop2Id,
        name: 'Sai Commercial & Residential Building',
        type: PropertyType.building,
        address: 'Main Market Road, Opp City Bank',
        city: 'Delhi',
        notes: 'Commercial shops on ground floor, rental rooms on 1st & 2nd floors',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        units: [
          const PropertyUnit(
            id: 'unit_shop_1',
            propertyId: prop2Id,
            unitName: 'Shop / Room 1',
            floor: 'Ground Floor',
            roomType: 'Commercial Room',
            monthlyRent: 22000,
            securityDeposit: 50000,
            status: UnitStatus.occupied,
            areaSqFt: 300,
            meterNumber: 'M-G1',
          ),
          const PropertyUnit(
            id: 'unit_shop_2',
            propertyId: prop2Id,
            unitName: 'Room 201',
            floor: '2nd Floor',
            roomType: 'Room with Bath',
            monthlyRent: 15000,
            securityDeposit: 30000,
            status: UnitStatus.vacant,
            areaSqFt: 260,
            meterNumber: 'M-201',
          ),
        ],
      ),
    ];
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PropertyRepository(prefs);
});

class PropertiesNotifier extends StateNotifier<List<Property>> {
  final PropertyRepository _repo;
  final Ref _ref;

  PropertiesNotifier(this._repo, this._ref) : super(_repo.getProperties());

  Future<void> addProperty({
    required String name,
    required PropertyType type,
    required String address,
    required String city,
    String? notes,
    int initialRoomCount = 0,
    int defaultRoomRent = 0,
    int defaultRoomDeposit = 0,
    int startingRoomNumber = 101,
    bool isSingleUnit = false,
    int singleUnitRent = 0,
    int singleUnitDeposit = 0,
  }) async {
    const uuid = Uuid();
    final propId = uuid.v4();

    List<PropertyUnit> initialUnits = [];
    if (initialRoomCount > 0) {
      for (int i = 0; i < initialRoomCount; i++) {
        final roomNum = startingRoomNumber + i;
        final floorNum = (roomNum ~/ 100);
        final floorStr = floorNum == 0
            ? 'Ground Floor'
            : (floorNum == 1 ? '1st Floor' : '${floorNum}nd Floor');

        initialUnits.add(
          PropertyUnit(
            id: uuid.v4(),
            propertyId: propId,
            unitName: 'Room $roomNum',
            floor: floorStr,
            roomType: 'Single Room',
            monthlyRent: defaultRoomRent,
            securityDeposit: defaultRoomDeposit,
            status: UnitStatus.vacant,
          ),
        );
      }
    } else if (isSingleUnit) {
      initialUnits.add(
        PropertyUnit(
          id: uuid.v4(),
          propertyId: propId,
          unitName: 'Room 1',
          monthlyRent: singleUnitRent,
          securityDeposit: singleUnitDeposit,
          status: UnitStatus.vacant,
        ),
      );
    }

    final newProp = Property(
      id: propId,
      name: name,
      type: type,
      address: address,
      city: city,
      notes: notes,
      createdAt: DateTime.now(),
      units: initialUnits,
    );

    final updated = [...state, newProp];
    state = updated;
    await _repo.saveProperties(updated);
  }

  Future<void> updateProperty(Property property) async {
    final updated = state.map((p) => p.id == property.id ? property : p).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }

  /// Deletes a building and cascade-removes its tenants, rent records, and expenses
  Future<void> deleteProperty(String propertyId) async {
    // 1. Cascade delete tenants for this property
    await _ref.read(tenantsProvider.notifier).removeTenantsForProperty(propertyId);

    // 2. Cascade delete rent entries for this property
    await _ref.read(rentLedgerProvider.notifier).removeEntriesForProperty(propertyId);

    // 3. Cascade delete expenses for this property
    await _ref.read(expensesProvider.notifier).removeExpensesForProperty(propertyId);

    // 4. Remove property from state and save
    final updated = state.where((p) => p.id != propertyId).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }

  Future<void> addUnit(String propertyId, PropertyUnit unit) async {
    final updated = state.map((p) {
      if (p.id == propertyId) {
        return p.copyWith(units: [...p.units, unit]);
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }

  Future<void> updateUnit(String propertyId, PropertyUnit unit) async {
    final updated = state.map((p) {
      if (p.id == propertyId) {
        final newUnits = p.units.map((u) => u.id == unit.id ? unit : u).toList();
        return p.copyWith(units: newUnits);
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }

  Future<void> setUnitOccupancy(String propertyId, String unitId, bool isOccupied) async {
    final updated = state.map((p) {
      if (p.id == propertyId) {
        final newUnits = p.units.map((u) {
          if (u.id == unitId) {
            return u.copyWith(
              status: isOccupied ? UnitStatus.occupied : UnitStatus.vacant,
            );
          }
          return u;
        }).toList();
        return p.copyWith(units: newUnits);
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }

  Future<void> deleteUnit(String propertyId, String unitId) async {
    // 1. Remove rent entries for this unit
    await _ref.read(rentLedgerProvider.notifier).removeEntriesForUnit(propertyId, unitId);

    // 2. Vacate or delete any tenant occupying this unit
    final occupants = _ref.read(tenantsProvider).where((t) => t.propertyId == propertyId && t.unitId == unitId).toList();
    for (final occ in occupants) {
      await _ref.read(tenantsProvider.notifier).deleteTenant(occ.id);
    }

    // 3. Remove unit from property
    final updated = state.map((p) {
      if (p.id == propertyId) {
        return p.copyWith(units: p.units.where((u) => u.id != unitId).toList());
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
  }
}

final propertiesProvider = StateNotifierProvider<PropertiesNotifier, List<Property>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  return PropertiesNotifier(repo, ref);
});
