import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../../../core/utils/date_formatter.dart';
import '../domain/models/tenant.dart';

class TenantRepository {
  static const String _prefKey = 'khatape_tenants';
  static const Set<String> _sampleTenantIds = {
    't_mahesh', 't_mahipal', 't_bablu', 't_kiran', 't_urmila', 't_khan',
    't_shyam_lal', 't_rinku', 't_jai_narayan', 't_sanjay', 't_pramod',
    't_shiv_nandan', 't_ramanuj', 't_suraj', 'tenant_ramesh', 'tenant_priya', 'tenant_amit_shop',
  };
  static const Set<String> _samplePropertyIds = {
    'prop_new_14', 'prop_sharma_complex', 'prop_sai_commercial', 'prop_green_residency',
  };

  final SharedPreferences _prefs;

  TenantRepository(this._prefs);

  List<Tenant> getTenants() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => Tenant.fromJson(e as Map<String, dynamic>))
            .where((t) => !_sampleTenantIds.contains(t.id) && !_samplePropertyIds.contains(t.propertyId))
            .toList();
        return loaded;
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveTenants(List<Tenant> tenants) async {
    final clean = tenants.where((t) => !_sampleTenantIds.contains(t.id) && !_samplePropertyIds.contains(t.propertyId)).toList();
    final encoded = jsonEncode(clean.map((t) => t.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }
}

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TenantRepository(prefs);
});

class TenantsNotifier extends StateNotifier<List<Tenant>> {
  final TenantRepository _repo;
  final Ref _ref;

  TenantsNotifier(this._repo, this._ref) : super(_repo.getTenants());

  Future<void> addTenant(Tenant tenant) async {
    // If the room already had another active occupant, mark the prior occupant moved out
    var currentTenants = state;
    final hasPriorOccupant = state.any((t) =>
        t.propertyId == tenant.propertyId &&
        t.unitId == tenant.unitId &&
        t.isActive &&
        t.id != tenant.id);

    if (hasPriorOccupant) {
      currentTenants = state.map((t) {
        if (t.propertyId == tenant.propertyId &&
            t.unitId == tenant.unitId &&
            t.isActive &&
            t.id != tenant.id) {
          return t.copyWith(isActive: false, moveOutDate: DateTime.now());
        }
        return t;
      }).toList();
    }

    final updated = [...currentTenants, tenant];
    state = updated;
    await _repo.saveTenants(updated);
    await FirebaseSyncService.syncTenant(tenant.toJson());

    // 1. Automatically mark the unit as occupied and sync rent if changed
    await _ref
        .read(propertiesProvider.notifier)
        .setUnitOccupancy(tenant.propertyId, tenant.unitId, true);

    final prop = _ref.read(propertiesProvider).where((p) => p.id == tenant.propertyId).firstOrNull;
    final unit = prop?.units.where((u) => u.id == tenant.unitId).firstOrNull;
    if (unit != null && unit.monthlyRent != tenant.monthlyRent) {
      await _ref.read(propertiesProvider.notifier).updateUnit(
        tenant.propertyId,
        unit.copyWith(
          monthlyRent: tenant.monthlyRent,
          securityDeposit: tenant.securityDeposit,
        ),
      );
    }

    // 2. Automatically generate rent entries for the current month so they appear immediately in dashboard & property detail
    try {
      final currentMonthKey = DateFormatter.toMonthKey(DateTime.now());
      await _ref.read(rentLedgerProvider.notifier).addOrUpdateEntryForTenant(tenant, currentMonthKey);

      final moveInMonthKey = DateFormatter.toMonthKey(tenant.moveInDate);
      if (moveInMonthKey != currentMonthKey) {
        await _ref.read(rentLedgerProvider.notifier).addOrUpdateEntryForTenant(tenant, moveInMonthKey);
      }
    } catch (_) {}
  }

  Future<void> updateTenant(Tenant tenant) async {
    // Find the previous version of this tenant to detect property/unit changes
    final previous = state.where((t) => t.id == tenant.id).firstOrNull;

    final updated = state.map((t) => t.id == tenant.id ? tenant : t).toList();
    state = updated;
    await _repo.saveTenants(updated);
    await FirebaseSyncService.syncTenant(tenant.toJson());

    // If the tenant moved to a different unit, free the old unit and occupy the new one
    if (previous != null) {
      final movedProperty = previous.propertyId != tenant.propertyId;
      final movedUnit = previous.unitId != tenant.unitId;

      if (movedProperty || movedUnit) {
        // Free the old unit
        await _ref
            .read(propertiesProvider.notifier)
            .setUnitOccupancy(previous.propertyId, previous.unitId, false);
      }

      // Always ensure the current unit is marked occupied (handles both
      // same-unit edits where status may have drifted, and unit changes)
      await _ref
          .read(propertiesProvider.notifier)
          .setUnitOccupancy(tenant.propertyId, tenant.unitId, true);

      // If rent amount changed and unit rent differs, sync the unit's rent too
      final prop = _ref.read(propertiesProvider).where((p) => p.id == tenant.propertyId).firstOrNull;
      final unit = prop?.units.where((u) => u.id == tenant.unitId).firstOrNull;
      if (unit != null && unit.monthlyRent != tenant.monthlyRent) {
        await _ref.read(propertiesProvider.notifier).updateUnit(
          tenant.propertyId,
          unit.copyWith(
            monthlyRent: tenant.monthlyRent,
            securityDeposit: tenant.securityDeposit,
          ),
        );
      }
    }
  }

  Future<void> markMovedOut(String tenantId, DateTime moveOutDate) async {
    Tenant? found;
    final updated = state.map((t) {
      if (t.id == tenantId) {
        found = t.copyWith(isActive: false, moveOutDate: moveOutDate);
        return found!;
      }
      return t;
    }).toList();
    state = updated;
    await _repo.saveTenants(updated);
    if (found != null) {
      await FirebaseSyncService.syncTenant(found!.toJson());
    }

    // Free up the unit to vacant
    if (found != null) {
      await _ref
          .read(propertiesProvider.notifier)
          .setUnitOccupancy(found!.propertyId, found!.unitId, false);
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    final tenant = state.where((t) => t.id == tenantId).firstOrNull;
    final updated = state.where((t) => t.id != tenantId).toList();
    state = updated;
    await _repo.saveTenants(updated);
    await FirebaseSyncService.deleteTenant(tenantId);

    // 1. Make unit vacant if tenant was found
    if (tenant != null) {
      await _ref
          .read(propertiesProvider.notifier)
          .setUnitOccupancy(tenant.propertyId, tenant.unitId, false);
    }

    // 2. Cascade delete all rent entries for this tenant so no ghost entries remain
    await _ref.read(rentLedgerProvider.notifier).removeEntriesForTenant(tenantId);
  }

  /// Remove all tenants belonging to a deleted building, cascading to their rent entries
  Future<void> removeTenantsForProperty(String propertyId) async {
    final propTenants = state.where((t) => t.propertyId == propertyId).toList();
    for (final t in propTenants) {
      await _ref.read(rentLedgerProvider.notifier).removeEntriesForTenant(t.id);
      await FirebaseSyncService.deleteTenant(t.id);
    }
    final updated = state.where((t) => t.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveTenants(updated);
  }

  Future<void> loadFromCloud(List<Tenant> tenants) async {
    state = tenants;
    await _repo.saveTenants(tenants);
  }

  Future<void> clearAllTenants() async {
    state = [];
    await _repo.saveTenants([]);
  }
}

final tenantsProvider = StateNotifierProvider<TenantsNotifier, List<Tenant>>((ref) {
  final repo = ref.watch(tenantRepositoryProvider);
  return TenantsNotifier(repo, ref);
});

