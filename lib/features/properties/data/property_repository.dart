import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../domain/models/property.dart';
import '../domain/models/unit.dart';

class PropertyRepository {
  static const String _prefKey = 'khatape_properties';
  static const Set<String> _samplePropertyIds = {
    'prop_new_14',
    'prop_sharma_complex',
    'prop_sai_commercial',
    'prop_green_residency',
  };

  final SharedPreferences _prefs;

  PropertyRepository(this._prefs);

  List<Property> getProperties() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => Property.fromJson(e as Map<String, dynamic>))
            .where((p) => !_samplePropertyIds.contains(p.id))
            .toList();
        return loaded;
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveProperties(List<Property> properties) async {
    final clean = properties.where((p) => !_samplePropertyIds.contains(p.id)).toList();
    final encoded = jsonEncode(clean.map((p) => p.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
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
    await FirebaseSyncService.syncProperty(newProp.toJson());
  }

  Future<void> updateProperty(Property property) async {
    final updated = state.map((p) => p.id == property.id ? property : p).toList();
    state = updated;
    await _repo.saveProperties(updated);
    await FirebaseSyncService.syncProperty(property.toJson());
  }

  /// Deletes a building and cascade-removes its tenants, rent records, and expenses
  Future<void> deleteProperty(String propertyId) async {
    try {
      // 1. Cascade delete tenants for this property
      await _ref.read(tenantsProvider.notifier).removeTenantsForProperty(propertyId);
    } catch (_) {}

    try {
      // 2. Cascade delete rent entries for this property
      await _ref.read(rentLedgerProvider.notifier).removeEntriesForProperty(propertyId);
    } catch (_) {}

    try {
      // 3. Cascade delete expenses for this property
      await _ref.read(expensesProvider.notifier).removeExpensesForProperty(propertyId);
    } catch (_) {}

    // 4. Remove property from state and save
    final updated = state.where((p) => p.id != propertyId).toList();
    state = updated;
    await _repo.saveProperties(updated);
    try {
      await FirebaseSyncService.deleteProperty(propertyId);
    } catch (_) {}
  }

  Future<void> addUnit(String propertyId, PropertyUnit unit) async {
    Property? changed;
    final updated = state.map((p) {
      if (p.id == propertyId) {
        changed = p.copyWith(units: [...p.units, unit]);
        return changed!;
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
    if (changed != null) {
      await FirebaseSyncService.syncProperty(changed!.toJson());
    }
  }

  Future<void> updateUnit(String propertyId, PropertyUnit unit) async {
    Property? changed;
    final updated = state.map((p) {
      if (p.id == propertyId) {
        final newUnits = p.units.map((u) => u.id == unit.id ? unit : u).toList();
        changed = p.copyWith(units: newUnits);
        return changed!;
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
    if (changed != null) {
      await FirebaseSyncService.syncProperty(changed!.toJson());
    }
  }

  Future<void> setUnitOccupancy(String propertyId, String unitId, bool isOccupied) async {
    Property? changed;
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
        changed = p.copyWith(units: newUnits);
        return changed!;
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
    if (changed != null) {
      await FirebaseSyncService.syncProperty(changed!.toJson());
    }
  }

  Future<void> clearAllProperties() async {
    state = [];
    await _repo.saveProperties([]);
  }

  Future<void> loadFromCloud(List<Property> properties) async {
    state = properties;
    await _repo.saveProperties(properties);
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
    Property? changed;
    final updated = state.map((p) {
      if (p.id == propertyId) {
        changed = p.copyWith(units: p.units.where((u) => u.id != unitId).toList());
        return changed!;
      }
      return p;
    }).toList();
    state = updated;
    await _repo.saveProperties(updated);
    if (changed != null) {
      await FirebaseSyncService.syncProperty(changed!.toJson());
    }
  }
}

final propertiesProvider = StateNotifierProvider<PropertiesNotifier, List<Property>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  return PropertiesNotifier(repo, ref);
});
