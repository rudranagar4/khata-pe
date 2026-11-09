import 'package:uuid/uuid.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../tenants/domain/models/tenant.dart';
import '../models/rent_entry.dart';
import '../models/payment.dart';

class MonthSummary {
  final int totalExpected;
  final int totalReceived;
  final int totalDue;
  final int totalOverdue;
  final int overdueCount;
  final int totalTenants;
  final int paidCount;
  final int partialCount;
  final int upcomingCount;
  final int cashPaymentsCount;
  final int cashAmount;
  final int bankPaymentsCount;
  final int bankAmount;

  const MonthSummary({
    required this.totalExpected,
    required this.totalReceived,
    required this.totalDue,
    required this.totalOverdue,
    required this.overdueCount,
    required this.totalTenants,
    required this.paidCount,
    required this.partialCount,
    required this.upcomingCount,
    this.cashPaymentsCount = 0,
    this.cashAmount = 0,
    this.bankPaymentsCount = 0,
    this.bankAmount = 0,
  });

  int get totalPaymentsCount => cashPaymentsCount + bankPaymentsCount;
  int get totalPaymentsAmount => cashAmount + bankAmount;

  double get collectionPercentage {
    if (totalExpected <= 0) return 0.0;
    final percent = (totalReceived / totalExpected) * 100;
    return percent > 100 ? 100.0 : (percent < 0 ? 0.0 : percent);
  }
}

class RentCalculator {
  static const _uuid = Uuid();

  /// Calculates pro-rata rent for a tenant moving in mid-month
  /// (days occupied / days in month * rent)
  static int calculateProRata(int fullMonthlyRent, DateTime moveInDate, DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    if (moveInDate.year == monthDate.year && moveInDate.month == monthDate.month) {
      final daysOccupied = (daysInMonth - moveInDate.day) + 1;
      if (daysOccupied <= 0) return 0;
      if (daysOccupied >= daysInMonth) return fullMonthlyRent;
      return ((daysOccupied / daysInMonth) * fullMonthlyRent).round();
    }
    return fullMonthlyRent;
  }

  /// Calculates summary statistics for a list of rent entries for a month
  static MonthSummary calculateSummary(List<RentEntry> entries) {
    int totalExpected = 0;
    int totalReceived = 0;
    int totalDue = 0;
    int totalOverdue = 0;
    int overdueCount = 0;
    int paidCount = 0;
    int partialCount = 0;
    int upcomingCount = 0;
    int cashPaymentsCount = 0;
    int cashAmount = 0;
    int bankPaymentsCount = 0;
    int bankAmount = 0;

    for (final entry in entries) {
      totalExpected += entry.totalPayable;
      totalReceived += entry.totalCollected;
      
      final balance = entry.balanceDue;
      totalDue += balance;

      for (final p in entry.payments) {
        if (p.mode == PaymentMode.cash) {
          cashPaymentsCount++;
          cashAmount += p.amount;
        } else if (p.mode == PaymentMode.bank) {
          bankPaymentsCount++;
          bankAmount += p.amount;
        }
      }

      switch (entry.status) {
        case RentStatus.paid:
          paidCount++;
          break;
        case RentStatus.partiallyPaid:
          partialCount++;
          if (entry.daysOverdue > 0) {
            totalOverdue += balance;
            overdueCount++;
          }
          break;
        case RentStatus.overdue:
          totalOverdue += balance;
          overdueCount++;
          break;
        case RentStatus.due:
        case RentStatus.upcoming:
          upcomingCount++;
          break;
      }
    }

    return MonthSummary(
      totalExpected: totalExpected,
      totalReceived: totalReceived,
      totalDue: totalDue,
      totalOverdue: totalOverdue,
      overdueCount: overdueCount,
      totalTenants: entries.length,
      paidCount: paidCount,
      partialCount: partialCount,
      upcomingCount: upcomingCount,
      cashPaymentsCount: cashPaymentsCount,
      cashAmount: cashAmount,
      bankPaymentsCount: bankPaymentsCount,
      bankAmount: bankAmount,
    );
  }

  /// Auto-generates RentEntry for active tenants if they don't have one for the month
  static List<RentEntry> generateMissingEntries({
    required String monthKey,
    required List<Tenant> tenants,
    required List<RentEntry> existingEntries,
    Map<String, int> tenantAdvanceBalances = const {},
  }) {
    final monthDate = DateFormatter.fromMonthKey(monthKey);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final List<RentEntry> result = List.from(existingEntries);

    for (final tenant in tenants) {
      if (!tenant.isActive) continue;

      // Don't generate if tenant moved in after this month
      final tenantMoveInMonth = DateTime(tenant.moveInDate.year, tenant.moveInDate.month, 1);
      if (monthDate.isBefore(tenantMoveInMonth)) continue;

      // Check if entry already exists
      final hasEntry = result.any((e) => e.tenantId == tenant.id && e.month == monthKey);
      if (hasEntry) continue;

      // Compute due date
      final dueDay = tenant.rentDueDay.clamp(1, daysInMonth);
      final dueDate = DateTime(monthDate.year, monthDate.month, dueDay);

      // Check pro-rata rent if moved in during this month
      final expectedRent = calculateProRata(tenant.monthlyRent, tenant.moveInDate, monthDate);

      // Check if advance payment carries forward from previous month
      final advanceCredit = tenantAdvanceBalances[tenant.id] ?? 0;

      final entry = RentEntry(
        id: _uuid.v4(),
        tenantId: tenant.id,
        propertyId: tenant.propertyId,
        unitId: tenant.unitId,
        month: monthKey,
        expectedAmount: expectedRent,
        dueDate: dueDate,
        amountReceived: 0,
        advanceCreditApplied: advanceCredit,
        payments: const [],
      );

      result.add(entry);
    }

    return result;
  }
}

