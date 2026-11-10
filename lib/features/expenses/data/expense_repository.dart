import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/expense.dart';

class ExpenseRepository {
  static const String _prefKey = 'khatape_expenses';
  final SharedPreferences _prefs;

  ExpenseRepository(this._prefs);

  List<Expense> getExpenses() {
    final raw = _prefs.getString(_prefKey);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final expenses = list.map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
        bool migrated = false;
        final updated = expenses.map((e) {
          if (e.propertyId == 'prop_green_residency') {
            migrated = true;
            return e.copyWith(propertyId: 'prop_sai_commercial');
          }
          return e;
        }).toList();
        if (migrated) {
          saveExpenses(updated);
        }
        return updated;
      } catch (_) {}
    }
    return _getSeedExpenses();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await _prefs.setString(_prefKey, encoded);
  }

  List<Expense> _getSeedExpenses() {
    final now = DateTime.now();
    return [
      Expense(
        id: 'exp_1',
        propertyId: 'prop_sharma_complex',
        category: ExpenseCategory.repairs,
        amount: 1500,
        date: DateTime(now.year, now.month, 3),
        note: 'Bathroom tap & pipe replacement in 101',
      ),
      Expense(
        id: 'exp_2',
        propertyId: 'prop_sharma_complex',
        category: ExpenseCategory.societyCharges,
        amount: 2200,
        date: DateTime(now.year, now.month, 1),
        note: 'Monthly society maintenance & guard salary share',
      ),
      Expense(
        id: 'exp_3',
        propertyId: 'prop_sai_commercial',
        category: ExpenseCategory.propertyTax,
        amount: 4500,
        date: DateTime(now.year, now.month - 1, 15),
        note: 'Municipal corporation annual property tax instalment',
      ),
    ];
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
  }

  Future<void> deleteExpense(String expenseId) async {
    final updated = state.where((e) => e.id != expenseId).toList();
    state = updated;
    await _repo.saveExpenses(updated);
  }

  /// Remove all expenses associated with a deleted property
  Future<void> removeExpensesForProperty(String propertyId) async {
    final updated = state.where((e) => e.propertyId != propertyId).toList();
    state = updated;
    await _repo.saveExpenses(updated);
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repo);
});

