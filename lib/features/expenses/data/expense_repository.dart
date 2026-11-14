import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/firebase_sync_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/expense.dart';

class ExpenseRepository {
  static const String _prefKey = 'khatape_expenses';
  static const Set<String> _sampleExpenseIds = {'exp_1', 'exp_2', 'exp_3'};
  static const Set<String> _samplePropertyIds = {
    'prop_new_14', 'prop_sharma_complex', 'prop_sai_commercial', 'prop_green_residency',
  };

  final SharedPreferences _prefs;

  ExpenseRepository(this._prefs);

  List<Expense> getExpenses() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final expenses = list
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .where((e) => !_sampleExpenseIds.contains(e.id) && !_samplePropertyIds.contains(e.propertyId))
            .toList();
        return expenses;
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final clean = expenses
        .where((e) => !_sampleExpenseIds.contains(e.id) && !_samplePropertyIds.contains(e.propertyId))
        .toList();
    final encoded = jsonEncode(clean.map((e) => e.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExpenseRepository(prefs);
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repo;
  static const _uuid = Uuid();

  ExpensesNotifier(this._repo) : super(_repo.getExpenses());

  Future<void> addExpense({
    required String propertyId,
    required ExpenseCategory category,
    required int amount,
    required DateTime date,
    String? note,
    String? billPhotoUrl,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      propertyId: propertyId,
      category: category,
      amount: amount,
      date: date,
      note: note,
      billPhotoUrl: billPhotoUrl,
    );
    final updated = [expense, ...state];
    state = updated;
    await _repo.saveExpenses(updated);
    await FirebaseSyncService.syncExpense(expense.toJson());
  }

  Future<void> deleteExpense(String expenseId) async {
    final updated = state.where((e) => e.id != expenseId).toList();
    state = updated;
    await _repo.saveExpenses(updated);
    await FirebaseSyncService.deleteExpense(expenseId);
  }

  /// Remove all expenses associated with a deleted property
  Future<void> removeExpensesForProperty(String propertyId) async {
    final toRemove = state.where((e) => e.propertyId == propertyId).toList();
    for (final e in toRemove) {
      await FirebaseSyncService.deleteExpense(e.id);
    }
    final updated = state.where((e) => e.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveExpenses(updated);
  }

  Future<void> loadFromCloud(List<Expense> expenses) async {
    state = expenses;
    await _repo.saveExpenses(expenses);
  }

  Future<void> clearAllExpenses() async {
    state = [];
    await _repo.saveExpenses([]);
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repo);
});
