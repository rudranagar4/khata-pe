import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../tenants/data/tenant_repository.dart';
import '../../tenants/domain/models/tenant.dart';
import '../domain/models/rent_entry.dart';
import '../domain/models/payment.dart';
import '../domain/services/rent_calculator.dart';
import '../../../../core/utils/date_formatter.dart';

class RentRepository {
  static const String _prefKey = 'khatape_rent_entries';
  static const String _prefReceiptCounterKey = 'khatape_receipt_counter';
  static const Set<String> _sampleRentEntryIds = {
    're_new14_1', 're_new14_2', 're_new14_3', 're_new14_4', 're_new14_5',
    're_new14_6', 're_new14_7', 're_new14_8', 're_new14_9', 're_new14_10',
    're_new14_11', 're_new14_12', 're_new14_13', 're_new14_14',
    'entry_ramesh_current', 'entry_priya_current', 'entry_amit_current',
    'entry_ramesh_prev', 'entry_priya_prev',
  };
  static const Set<String> _samplePropertyIds = {
    'prop_new_14', 'prop_sharma_complex', 'prop_sai_commercial', 'prop_green_residency',
  };

  final SharedPreferences _prefs;

  RentRepository(this._prefs);

  List<RentEntry> getRentEntries() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final entries = list
            .map((e) => RentEntry.fromJson(e as Map<String, dynamic>))
            .where((e) => !_sampleRentEntryIds.contains(e.id) && !_samplePropertyIds.contains(e.propertyId))
            .toList();
        return entries;
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveRentEntries(List<RentEntry> entries) async {
    final clean = entries
        .where((e) => !_sampleRentEntryIds.contains(e.id) && !_samplePropertyIds.contains(e.propertyId))
        .toList();
    final encoded = jsonEncode(clean.map((e) => e.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }

  int getNextReceiptNumber() {
    final current = _prefs.getInt(_prefReceiptCounterKey) ?? 1000;
    final next = current + 1;
    _prefs.setInt(_prefReceiptCounterKey, next);
    return next;
  }
}

final rentRepositoryProvider = Provider<RentRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RentRepository(prefs);
});

class RentLedgerNotifier extends StateNotifier<List<RentEntry>> {
  final RentRepository _repo;
  final Ref _ref;
  static const _uuid = Uuid();

  RentLedgerNotifier(this._repo, this._ref) : super(_repo.getRentEntries());

  /// Ensures rent entries exist for the specified monthKey
  void ensureMonthEntries(String monthKey) {
    final tenants = _ref.read(tenantsProvider);

    // Compute any excess advances from previous month
    final prevMonthKey = DateFormatter.getPreviousMonth(monthKey);
    final prevEntries = state.where((e) => e.month == prevMonthKey).toList();
    final Map<String, int> advanceMap = {};
    for (final pe in prevEntries) {
      if (pe.excessAdvance > 0) {
        advanceMap[pe.tenantId] = pe.excessAdvance;
      }
    }

    final updated = RentCalculator.generateMissingEntries(
      monthKey: monthKey,
      tenants: tenants,
      existingEntries: state,
      tenantAdvanceBalances: advanceMap,
    );

    if (updated.length != state.length) {
      state = updated;
      _repo.saveRentEntries(updated);
    }
  }

  /// Immediately creates and saves a rent entry for a tenant in the target month if missing
  Future<RentEntry> addOrUpdateEntryForTenant(Tenant tenant, String monthKey) async {
    final existing = state.where((e) => e.tenantId == tenant.id && e.month == monthKey).firstOrNull;
    if (existing != null) return existing;

    final monthDate = DateFormatter.fromMonthKey(monthKey);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final dueDay = tenant.rentDueDay.clamp(1, daysInMonth);
    final dueDate = DateTime(monthDate.year, monthDate.month, dueDay);
    final expectedRent = RentCalculator.calculateProRata(tenant.monthlyRent, tenant.moveInDate, monthDate);

    final newEntry = RentEntry(
      id: _uuid.v4(),
      tenantId: tenant.id,
      propertyId: tenant.propertyId,
      unitId: tenant.unitId,
      month: monthKey,
      expectedAmount: expectedRent,
      dueDate: dueDate,
      amountReceived: 0,
      payments: const [],
    );

    final updated = [...state, newEntry];
    state = updated;
    await _repo.saveRentEntries(updated);
    await FirebaseSyncService.syncRentEntry(newEntry.toJson());
    return newEntry;
  }

  /// Remove all rent entries for a specific tenant (called upon tenant deletion)
  Future<void> removeEntriesForTenant(String tenantId) async {
    final toRemove = state.where((e) => e.tenantId == tenantId).toList();
    for (final e in toRemove) {
      await FirebaseSyncService.deleteRentEntry(e.id);
    }
    final updated = state.where((e) => e.tenantId != tenantId).toList();
    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Remove all rent entries for a specific property (called upon property deletion)
  Future<void> removeEntriesForProperty(String propertyId) async {
    final toRemove = state.where((e) => e.propertyId == propertyId).toList();
    for (final e in toRemove) {
      await FirebaseSyncService.deleteRentEntry(e.id);
    }
    final updated = state.where((e) => e.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Remove all rent entries for a specific unit (called upon room deletion)
  Future<void> removeEntriesForUnit(String propertyId, String unitId) async {
    final toRemove = state.where((e) => e.propertyId == propertyId && e.unitId == unitId).toList();
    for (final e in toRemove) {
      await FirebaseSyncService.deleteRentEntry(e.id);
    }
    final updated = state.where((e) => !(e.propertyId == propertyId && e.unitId == unitId)).toList();
    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Record payment against a RentEntry
  Future<Payment> recordPayment({
    required String rentEntryId,
    required int amount,
    required DateTime date,
    required PaymentMode mode,
    String? referenceNo,
    String? note,
  }) async {
    final nextNumber = _repo.getNextReceiptNumber();
    final year = date.year;
    final receiptNo = 'KP-$year-$nextNumber';

    final payment = Payment(
      id: _uuid.v4(),
      rentEntryId: rentEntryId,
      amount: amount,
      date: date,
      mode: mode,
      referenceNo: referenceNo,
      note: note,
      receiptNo: receiptNo,
      createdAt: DateTime.now(),
    );

    RentEntry? changedEntry;
    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        final newReceived = entry.amountReceived + amount;
        final newPayments = [...entry.payments, payment];
        changedEntry = entry.copyWith(
          amountReceived: newReceived,
          payments: newPayments,
        );
        return changedEntry!;
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
    if (changedEntry != null) {
      await FirebaseSyncService.syncRentEntry(changedEntry!.toJson());
    }
    return payment;
  }

  /// Undo / remove a payment
  Future<void> undoPayment(String rentEntryId, String paymentId) async {
    RentEntry? changedEntry;
    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        final targetPay = entry.payments.firstWhere((p) => p.id == paymentId);
        final newReceived = entry.amountReceived - targetPay.amount;
        final newPayments = entry.payments.where((p) => p.id != paymentId).toList();
        changedEntry = entry.copyWith(
          amountReceived: newReceived < 0 ? 0 : newReceived,
          payments: newPayments,
        );
        return changedEntry!;
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
    if (changedEntry != null) {
      await FirebaseSyncService.syncRentEntry(changedEntry!.toJson());
    }
  }

  /// Override rent amount or add utility charges / late fee
  Future<void> updateRentCharges({
    required String rentEntryId,
    int? expectedAmount,
    int? extraCharges,
    String? extraChargesNote,
  }) async {
    RentEntry? changedEntry;
    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        changedEntry = entry.copyWith(
          expectedAmount: expectedAmount ?? entry.expectedAmount,
          extraCharges: extraCharges ?? entry.extraCharges,
          extraChargesNote: extraChargesNote ?? entry.extraChargesNote,
        );
        return changedEntry!;
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
    if (changedEntry != null) {
      await FirebaseSyncService.syncRentEntry(changedEntry!.toJson());
    }
  }

  Future<void> loadFromCloud(List<RentEntry> entries) async {
    state = entries;
    await _repo.saveRentEntries(entries);
  }

  Future<void> clearAllRentEntries() async {
    state = [];
    await _repo.saveRentEntries([]);
  }
}

final rentLedgerProvider = StateNotifierProvider<RentLedgerNotifier, List<RentEntry>>((ref) {
  final repo = ref.watch(rentRepositoryProvider);
  return RentLedgerNotifier(repo, ref);
});

/// Filtered provider for selected month
final selectedMonthProvider = StateProvider<String>((ref) {
  return DateFormatter.toMonthKey(DateTime.now());
});

final currentMonthEntriesProvider = Provider<List<RentEntry>>((ref) {
  final monthKey = ref.watch(selectedMonthProvider);
  final allEntries = ref.watch(rentLedgerProvider);
  return allEntries.where((e) => e.month == monthKey).toList();
});
