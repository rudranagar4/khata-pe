import 'package:flutter_test/flutter_test.dart';
import 'package:khatape/core/utils/currency_formatter.dart';
import 'package:khatape/features/rent/domain/models/payment.dart';
import 'package:khatape/features/rent/domain/models/rent_entry.dart';
import 'package:khatape/features/rent/domain/services/rent_calculator.dart';

void main() {
  group('Rent Status Calculation Tests', () {
    test('Status is paid when total collected equals expected amount', () {
      final entry = RentEntry(
        id: '1',
        tenantId: 't1',
        propertyId: 'p1',
        unitId: 'u1',
        month: '2026-11',
        expectedAmount: 10000,
        dueDate: DateTime(2026, 11, 5),
        amountReceived: 10000,
      );

      expect(entry.status, RentStatus.paid);
      expect(entry.balanceDue, 0);
      expect(entry.excessAdvance, 0);
    });

    test('Status is partiallyPaid when amount received is between 0 and total payable', () {
      final entry = RentEntry(
        id: '2',
        tenantId: 't1',
        propertyId: 'p1',
        unitId: 'u1',
        month: '2026-11',
        expectedAmount: 10000,
        dueDate: DateTime(2026, 11, 5),
        amountReceived: 6000,
      );

      expect(entry.status, RentStatus.partiallyPaid);
      expect(entry.balanceDue, 4000);
    });

    test('Status is overdue when unpaid and today is after due date', () {
      final entry = RentEntry(
        id: '3',
        tenantId: 't1',
        propertyId: 'p1',
        unitId: 'u1',
        month: '2026-10',
        expectedAmount: 10000,
        dueDate: DateTime(2026, 10, 5), // Past due
        amountReceived: 0,
      );

      expect(entry.status, RentStatus.overdue);
      expect(entry.balanceDue, 10000);
      expect(entry.daysOverdue > 0, true);
    });

    test('Excess payment creates advance balance', () {
      final entry = RentEntry(
        id: '4',
        tenantId: 't1',
        propertyId: 'p1',
        unitId: 'u1',
        month: '2026-11',
        expectedAmount: 10000,
        dueDate: DateTime(2026, 11, 5),
        amountReceived: 15000,
      );

      expect(entry.status, RentStatus.paid);
      expect(entry.excessAdvance, 5000);
      expect(entry.balanceDue, 0);
    });
  });

  group('Pro-Rata Rent Calculation Tests', () {
    test('Calculates half-month rent if moving in on 16th of 30-day month', () {
      final moveInDate = DateTime(2026, 11, 16);
      final monthDate = DateTime(2026, 11, 1);
      final proRata = RentCalculator.calculateProRata(10000, moveInDate, monthDate);

      // November has 30 days. Occupied from 16 to 30 = 15 days = exactly 50%
      expect(proRata, 5000);
    });

    test('Full rent if moved in before current month', () {
      final moveInDate = DateTime(2026, 8, 1);
      final monthDate = DateTime(2026, 11, 1);
      final rent = RentCalculator.calculateProRata(10000, moveInDate, monthDate);

      expect(rent, 10000);
    });
  });

  group('Summary Statistics Tests', () {
    test('Calculates correct total expected, received, due, and collection percentage', () {
      final entries = [
        RentEntry(
          id: '1',
          tenantId: 't1',
          propertyId: 'p1',
          unitId: 'u1',
          month: '2026-11',
          expectedAmount: 10000,
          dueDate: DateTime(2026, 11, 5),
          amountReceived: 10000,
        ),
        RentEntry(
          id: '2',
          tenantId: 't2',
          propertyId: 'p1',
          unitId: 'u2',
          month: '2026-11',
          expectedAmount: 10000,
          dueDate: DateTime(2026, 11, 5),
          amountReceived: 5000,
        ),
        RentEntry(
          id: '3',
          tenantId: 't3',
          propertyId: 'p1',
          unitId: 'u3',
          month: '2026-11',
          expectedAmount: 10000,
          dueDate: DateTime(2026, 11, 5),
          amountReceived: 0,
        ),
      ];

      final summary = RentCalculator.calculateSummary(entries);

      expect(summary.totalExpected, 30000);
      expect(summary.totalReceived, 15000);
      expect(summary.totalDue, 15000);
      expect(summary.paidCount, 1);
      expect(summary.partialCount, 1);
      expect(summary.collectionPercentage, 50.0);
    });

    test('Calculates Cash vs Bank payment counts and amounts accurately', () {
      final entries = [
        RentEntry(
          id: '1',
          tenantId: 't1',
          propertyId: 'p1',
          unitId: 'u1',
          month: '2026-11',
          expectedAmount: 10000,
          dueDate: DateTime(2026, 11, 5),
          amountReceived: 10000,
          payments: [
            Payment(
              id: 'p1',
              rentEntryId: '1',
              amount: 6000,
              date: DateTime(2026, 11, 2),
              mode: PaymentMode.cash,
              receiptNo: 'KP-1',
            ),
            Payment(
              id: 'p2',
              rentEntryId: '1',
              amount: 4000,
              date: DateTime(2026, 11, 4),
              mode: PaymentMode.bank,
              receiptNo: 'KP-2',
            ),
          ],
        ),
        RentEntry(
          id: '2',
          tenantId: 't2',
          propertyId: 'p1',
          unitId: 'u2',
          month: '2026-11',
          expectedAmount: 5000,
          dueDate: DateTime(2026, 11, 5),
          amountReceived: 5000,
          payments: [
            Payment(
              id: 'p3',
              rentEntryId: '2',
              amount: 5000,
              date: DateTime(2026, 11, 3),
              mode: PaymentMode.cash,
              receiptNo: 'KP-3',
            ),
          ],
        ),
      ];

      final summary = RentCalculator.calculateSummary(entries);

      expect(summary.cashPaymentsCount, 2);
      expect(summary.cashAmount, 11000);
      expect(summary.bankPaymentsCount, 1);
      expect(summary.bankAmount, 4000);
      expect(summary.totalPaymentsCount, 3);
      expect(summary.totalPaymentsAmount, 15000);
    });
  });

  group('Currency Formatter Tests', () {
    test('Formats Indian amounts correctly', () {
      expect(CurrencyFormatter.format(8500), '₹8,500');
      expect(CurrencyFormatter.format(125000), '₹1,25,000');
      expect(CurrencyFormatter.format(10000000), '₹1,00,00,000');
    });

    test('Parses text to integer rupees', () {
      expect(CurrencyFormatter.parse('₹1,25,000'), 125000);
      expect(CurrencyFormatter.parse('8500'), 8500);
    });
  });
}

