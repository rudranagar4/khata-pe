import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/data/auth_repository.dart';
import '../../properties/data/property_repository.dart';
import '../../rent/data/rent_repository.dart';
import '../../../../core/utils/date_formatter.dart';
import '../domain/models/tenant.dart';

class TenantRepository {
  static const String _prefKey = 'khatape_tenants';
  final SharedPreferences _prefs;

  TenantRepository(this._prefs);

  List<Tenant> getTenants() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => Tenant.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return _getSeedTenants();
  }

  Future<void> saveTenants(List<Tenant> tenants) async {
    final encoded = jsonEncode(tenants.map((t) => t.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }

  List<Tenant> _getSeedTenants() {
    return [
      // NEW 14 Tenants (from Ledger Image)
      Tenant(id: 't_mahesh', name: 'MAHESH PAINTER', phone: '9876510001', propertyId: 'prop_new_14', unitId: 'unit_new14_1', moveInDate: DateTime(2024, 8, 25), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_mahipal', name: 'MAHIPAL', phone: '9876510002', propertyId: 'prop_new_14', unitId: 'unit_new14_2', moveInDate: DateTime(2026, 6, 28), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_bablu', name: 'BABLU', phone: '9876510003', propertyId: 'prop_new_14', unitId: 'unit_new14_3', moveInDate: DateTime(2012, 2, 1), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_kiran', name: 'KIRAN', phone: '9876510004', propertyId: 'prop_new_14', unitId: 'unit_new14_4', moveInDate: DateTime(2016, 4, 13), monthlyRent: 2630, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_urmila', name: 'URMILA', phone: '9876510005', propertyId: 'prop_new_14', unitId: 'unit_new14_5', moveInDate: DateTime(2026, 6, 9), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_khan', name: 'KHAN', phone: '9876510006', propertyId: 'prop_new_14', unitId: 'unit_new14_6', moveInDate: DateTime(2026, 4, 5), monthlyRent: 2630, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_shyam_lal', name: 'SHYAM LAL', phone: '9876510007', propertyId: 'prop_new_14', unitId: 'unit_new14_7', moveInDate: DateTime(2018, 7, 20), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_rinku', name: 'RINKU', phone: '9876510008', propertyId: 'prop_new_14', unitId: 'unit_new14_8', moveInDate: DateTime(2021, 11, 22), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_jai_narayan', name: 'JAI NARAYAN', phone: '9876510009', propertyId: 'prop_new_14', unitId: 'unit_new14_9', moveInDate: DateTime(2010, 5, 17), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_sanjay', name: 'SANJAY', phone: '9876510010', propertyId: 'prop_new_14', unitId: 'unit_new14_10', moveInDate: DateTime(2026, 9, 4), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_pramod', name: 'PRAMOD', phone: '9876510011', propertyId: 'prop_new_14', unitId: 'unit_new14_11', moveInDate: DateTime(2021, 12, 26), monthlyRent: 2630, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_shiv_nandan', name: 'SHIV NANDAN', phone: '9876510012', propertyId: 'prop_new_14', unitId: 'unit_new14_12', moveInDate: DateTime(2026, 9, 20), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_ramanuj', name: 'RAMANUJ', phone: '9876510013', propertyId: 'prop_new_14', unitId: 'unit_new14_13', moveInDate: DateTime(2008, 8, 2), monthlyRent: 2630, rentDueDay: 5, securityDeposit: 5000),
      Tenant(id: 't_suraj', name: 'SURAJ', phone: '9876510014', propertyId: 'prop_new_14', unitId: 'unit_new14_14', moveInDate: DateTime(2025, 1, 1), monthlyRent: 2430, rentDueDay: 5, securityDeposit: 5000),

      // Other Tenants
      Tenant(
        id: 'tenant_ramesh',
        name: 'Ramesh Kumar',
        phone: '9876543210',
        altPhone: '9811122233',
        email: 'ramesh.k@gmail.com',
        idProofType: 'Aadhaar Card',
        idProofNumber: '4532 8901 1234',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_101',
        moveInDate: DateTime(2026, 1, 1),
        agreementEndDate: DateTime(2026, 12, 31),
        monthlyRent: 8500,
        rentDueDay: 5,
        securityDeposit: 17000,
        isActive: true,
        notes: 'Works at IT firm. Pays via UPI.',
      ),
      Tenant(
        id: 'tenant_priya',
        name: 'Priya Sharma',
        phone: '9812345678',
        email: 'priya.sharma@yahoo.com',
        idProofType: 'PAN Card',
        idProofNumber: 'ABCPS1234F',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_102',
        moveInDate: DateTime(2026, 2, 1),
        agreementEndDate: DateTime(2027, 1, 31),
        monthlyRent: 14000,
        rentDueDay: 1,
        securityDeposit: 28000,
        isActive: true,
        notes: 'Family of 3. Very prompt with rent.',
      ),
      Tenant(
        id: 'tenant_amit_shop',
        name: 'Amit Patel (Patel Electronics)',
        phone: '9988776655',
        idProofType: 'GSTIN / Trade License',
        idProofNumber: '07AAACP1234P1Z5',
        propertyId: 'prop_green_residency',
        unitId: 'unit_shop_1',
        moveInDate: DateTime(2025, 8, 1),
        agreementEndDate: DateTime(2027, 7, 31),
        monthlyRent: 22000,
        rentDueDay: 10,
        securityDeposit: 50000,
        isActive: true,
        notes: 'Ground floor shop tenant.',
      ),
    ];
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
    final updated = [...state, tenant];
    state = updated;
    await _repo.saveTenants(updated);

    // 1. Automatically mark the unit as occupied
    await _ref
        .read(propertiesProvider.notifier)
        .setUnitOccupancy(tenant.propertyId, tenant.unitId, true);

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
    final updated = state.map((t) => t.id == tenant.id ? tenant : t).toList();
    state = updated;
    await _repo.saveTenants(updated);
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
    }
    final updated = state.where((t) => t.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveTenants(updated);
  }
}

final tenantsProvider = StateNotifierProvider<TenantsNotifier, List<Tenant>>((ref) {
  final repo = ref.watch(tenantRepositoryProvider);
  return TenantsNotifier(repo, ref);
});

