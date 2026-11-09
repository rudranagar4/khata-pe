import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
  final SharedPreferences _prefs;

  RentRepository(this._prefs);

  List<RentEntry> getRentEntries() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => RentEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return _getSeedRentEntries();
  }

  Future<void> saveRentEntries(List<RentEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }

  int getNextReceiptNumber() {
    final current = _prefs.getInt(_prefReceiptCounterKey) ?? 1000;
    final next = current + 1;
    _prefs.setInt(_prefReceiptCounterKey, next);
    return next;
  }

  List<RentEntry> _getSeedRentEntries() {
    final now = DateTime.now();
    final currentMonthKey = DateFormatter.toMonthKey(now); // e.g. "2026-11"
    final prevMonthKey = DateFormatter.getPreviousMonth(currentMonthKey); // e.g. "2026-10"

    return [
      // NEW 14 Entries (Exact match to uploaded Khata Ledger)
      RentEntry(id: 're_new14_1', tenantId: 't_mahesh', propertyId: 'prop_new_14', unitId: 'unit_new14_1', month: currentMonthKey, openingBalance: 5380, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_2', tenantId: 't_mahipal', propertyId: 'prop_new_14', unitId: 'unit_new14_2', month: currentMonthKey, openingBalance: 1220, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_3', tenantId: 't_bablu', propertyId: 'prop_new_14', unitId: 'unit_new14_3', month: currentMonthKey, openingBalance: 6760, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_4', tenantId: 't_kiran', propertyId: 'prop_new_14', unitId: 'unit_new14_4', month: currentMonthKey, openingBalance: 0, expectedAmount: 2630, extraCharges: 800, extraChargesNote: 'Electricity', dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_5', tenantId: 't_urmila', propertyId: 'prop_new_14', unitId: 'unit_new14_5', month: currentMonthKey, openingBalance: 730, expectedAmount: 2430, extraCharges: 300, extraChargesNote: 'Electricity', dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_6', tenantId: 't_khan', propertyId: 'prop_new_14', unitId: 'unit_new14_6', month: currentMonthKey, openingBalance: 0, expectedAmount: 2630, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_7', tenantId: 't_shyam_lal', propertyId: 'prop_new_14', unitId: 'unit_new14_7', month: currentMonthKey, openingBalance: 2430, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_8', tenantId: 't_rinku', propertyId: 'prop_new_14', unitId: 'unit_new14_8', month: currentMonthKey, openingBalance: 0, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_9', tenantId: 't_jai_narayan', propertyId: 'prop_new_14', unitId: 'unit_new14_9', month: currentMonthKey, openingBalance: 7160, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_10', tenantId: 't_sanjay', propertyId: 'prop_new_14', unitId: 'unit_new14_10', month: currentMonthKey, openingBalance: 30, expectedAmount: 2430, extraCharges: 300, extraChargesNote: 'Electricity', dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_11', tenantId: 't_pramod', propertyId: 'prop_new_14', unitId: 'unit_new14_11', month: currentMonthKey, openingBalance: 7880, expectedAmount: 2630, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_12', tenantId: 't_shiv_nandan', propertyId: 'prop_new_14', unitId: 'unit_new14_12', month: currentMonthKey, openingBalance: 0, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_13', tenantId: 't_ramanuj', propertyId: 'prop_new_14', unitId: 'unit_new14_13', month: currentMonthKey, openingBalance: 5690, expectedAmount: 2630, extraCharges: 300, extraChargesNote: 'Electricity', dueDate: DateTime(now.year, now.month, 5)),
      RentEntry(id: 're_new14_14', tenantId: 't_suraj', propertyId: 'prop_new_14', unitId: 'unit_new14_14', month: currentMonthKey, openingBalance: 5500, expectedAmount: 2430, extraCharges: 0, dueDate: DateTime(now.year, now.month, 5)),

      // Current Month - Ramesh: Paid in Full
      RentEntry(
        id: 'entry_ramesh_current',
        tenantId: 'tenant_ramesh',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_101',
        month: currentMonthKey,
        expectedAmount: 8500,
        extraCharges: 450, // Electricity reading
        extraChargesNote: 'Electricity bill (90 units @ ₹5)',
        dueDate: DateTime(now.year, now.month, 5),
        amountReceived: 8950,
        payments: [
          Payment(
            id: 'pay_1',
            rentEntryId: 'entry_ramesh_current',
            amount: 8950,
            date: DateTime(now.year, now.month, 4),
            mode: PaymentMode.cash,
            referenceNo: 'Cash Received',
            receiptNo: 'KP-2026-1001',
            note: 'Paid in cash at room',
          ),
        ],
      ),

      // Current Month - Priya: Partially Paid
      RentEntry(
        id: 'entry_priya_current',
        tenantId: 'tenant_priya',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_102',
        month: currentMonthKey,
        expectedAmount: 14000,
        dueDate: DateTime(now.year, now.month, 1),
        amountReceived: 8000,
        payments: [
          Payment(
            id: 'pay_2',
            rentEntryId: 'entry_priya_current',
            amount: 8000,
            date: DateTime(now.year, now.month, 2),
            mode: PaymentMode.bank,
            referenceNo: 'IMPS/HDFC/882199',
            receiptNo: 'KP-2026-1002',
            note: 'First installment via Bank. Remaining next week.',
          ),
        ],
      ),

      // Current Month - Amit Patel Shop: Overdue / Due
      RentEntry(
        id: 'entry_amit_current',
        tenantId: 'tenant_amit_shop',
        propertyId: 'prop_green_residency',
        unitId: 'unit_shop_1',
        month: currentMonthKey,
        expectedAmount: 22000,
        dueDate: DateTime(now.year, now.month, 10),
        amountReceived: 0,
        payments: [],
      ),

      // Previous Month - Historical Entries
      RentEntry(
        id: 'entry_ramesh_prev',
        tenantId: 'tenant_ramesh',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_101',
        month: prevMonthKey,
        expectedAmount: 8500,
        dueDate: DateTime(now.year, now.month - 1, 5),
        amountReceived: 8500,
        payments: [
          Payment(
            id: 'pay_prev_1',
            rentEntryId: 'entry_ramesh_prev',
            amount: 8500,
            date: DateTime(now.year, now.month - 1, 5),
            mode: PaymentMode.cash,
            receiptNo: 'KP-2026-0988',
          ),
        ],
      ),
      RentEntry(
        id: 'entry_priya_prev',
        tenantId: 'tenant_priya',
        propertyId: 'prop_sharma_complex',
        unitId: 'unit_102',
        month: prevMonthKey,
        expectedAmount: 14000,
        dueDate: DateTime(now.year, now.month - 1, 1),
        amountReceived: 14000,
        payments: [
          Payment(
            id: 'pay_prev_2',
            rentEntryId: 'entry_priya_prev',
            amount: 14000,
            date: DateTime(now.year, now.month - 1, 1),
            mode: PaymentMode.bank,
            receiptNo: 'KP-2026-0989',
          ),
        ],
      ),
    ];
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
    return newEntry;
  }

  /// Remove all rent entries for a specific tenant (called upon tenant deletion)
  Future<void> removeEntriesForTenant(String tenantId) async {
    final updated = state.where((e) => e.tenantId != tenantId).toList();
    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Remove all rent entries for a specific property (called upon property deletion)
  Future<void> removeEntriesForProperty(String propertyId) async {
    final updated = state.where((e) => e.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Remove all rent entries for a specific unit (called upon room deletion)
  Future<void> removeEntriesForUnit(String propertyId, String unitId) async {
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

    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        final newReceived = entry.amountReceived + amount;
        final newPayments = [...entry.payments, payment];
        return entry.copyWith(
          amountReceived: newReceived,
          payments: newPayments,
        );
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
    return payment;
  }

  /// Undo / remove a payment
  Future<void> undoPayment(String rentEntryId, String paymentId) async {
    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        final targetPay = entry.payments.firstWhere((p) => p.id == paymentId);
        final newReceived = entry.amountReceived - targetPay.amount;
        final newPayments = entry.payments.where((p) => p.id != paymentId).toList();
        return entry.copyWith(
          amountReceived: newReceived < 0 ? 0 : newReceived,
          payments: newPayments,
        );
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
  }

  /// Override rent amount or add utility charges / late fee
  Future<void> updateRentCharges({
    required String rentEntryId,
    int? expectedAmount,
    int? extraCharges,
    String? extraChargesNote,
  }) async {
    final updated = state.map((entry) {
      if (entry.id == rentEntryId) {
        return entry.copyWith(
          expectedAmount: expectedAmount ?? entry.expectedAmount,
          extraCharges: extraCharges ?? entry.extraCharges,
          extraChargesNote: extraChargesNote ?? entry.extraChargesNote,
        );
      }
      return entry;
    }).toList();

    state = updated;
    await _repo.saveRentEntries(updated);
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

