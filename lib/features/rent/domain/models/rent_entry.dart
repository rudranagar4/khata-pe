import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'payment.dart';

enum RentStatus {
  paid,
  partiallyPaid,
  due,
  overdue,
  upcoming;

  String get displayName {
    switch (this) {
      case RentStatus.paid:
        return 'Paid';
      case RentStatus.partiallyPaid:
        return 'Partially Paid';
      case RentStatus.due:
        return 'Due Today';
      case RentStatus.overdue:
        return 'Overdue';
      case RentStatus.upcoming:
        return 'Upcoming';
    }
  }

  Color get color {
    switch (this) {
      case RentStatus.paid:
        return AppColors.statusPaid;
      case RentStatus.partiallyPaid:
        return AppColors.statusPartial;
      case RentStatus.overdue:
        return AppColors.statusOverdue;
      case RentStatus.due:
        return AppColors.accent;
      case RentStatus.upcoming:
        return AppColors.statusUpcoming;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RentStatus.paid:
        return AppColors.statusPaidBg;
      case RentStatus.partiallyPaid:
        return AppColors.statusPartialBg;
      case RentStatus.overdue:
        return AppColors.statusOverdueBg;
      case RentStatus.due:
        return AppColors.statusPartialBg;
      case RentStatus.upcoming:
        return AppColors.statusUpcomingBg;
    }
  }
}

class RentEntry {
  final String id;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final String month; // "YYYY-MM"
  final int openingBalance; // Op.Bal - Arrears / previous unpaid balance
  final int expectedAmount; // C.Mth - Current month rent
  final int extraCharges; // E. CITY - Electricity charges / sub-meter
  final String? extraChargesNote;
  final DateTime dueDate;
  final int amountReceived;
  final int advanceCreditApplied;
  final List<Payment> payments;
  final String? notes;

  const RentEntry({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.month,
    this.openingBalance = 0,
    required this.expectedAmount,
    this.extraCharges = 0,
    this.extraChargesNote,
    required this.dueDate,
    this.amountReceived = 0,
    this.advanceCreditApplied = 0,
    this.payments = const [],
    this.notes,
  });

  /// Subtotal = openingBalance + expectedAmount (Total before electricity in Khata)
  int get subtotal => openingBalance + expectedAmount;

  /// Total bill for this month (G. Total) = openingBalance + expectedAmount + extraCharges
  int get totalPayable => openingBalance + expectedAmount + extraCharges;

  /// Total collected = amountReceived + advanceCreditApplied
  int get totalCollected => amountReceived + advanceCreditApplied;

  /// Remaining balance (Clo Bal)
  int get balanceDue {
    final balance = totalPayable - totalCollected;
    return balance > 0 ? balance : 0;
  }

  /// Any excess payment that can advance carry-forward
  int get excessAdvance {
    final excess = totalCollected - totalPayable;
    return excess > 0 ? excess : 0;
  }

  /// Derived status as mandated by Section 6 of requirements
  RentStatus get status {
    if (totalCollected >= totalPayable && totalPayable > 0) {
      return RentStatus.paid;
    } else if (totalCollected > 0 && totalCollected < totalPayable) {
      return RentStatus.partiallyPaid;
    } else {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (todayDate.isAfter(due)) {
        return RentStatus.overdue;
      } else if (todayDate.isAtSameMomentAs(due)) {
        return RentStatus.due;
      } else {
        return RentStatus.upcoming;
      }
    }
  }

  /// Number of days overdue (0 if not overdue)
  int get daysOverdue {
    if (status != RentStatus.overdue && status != RentStatus.partiallyPaid) return 0;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (todayDate.isAfter(due)) {
      return todayDate.difference(due).inDays;
    }
    return 0;
  }

  RentEntry copyWith({
    String? id,
    String? tenantId,
    String? propertyId,
    String? unitId,
    String? month,
    int? openingBalance,
    int? expectedAmount,
    int? extraCharges,
    String? extraChargesNote,
    DateTime? dueDate,
    int? amountReceived,
    int? advanceCreditApplied,
    List<Payment>? payments,
    String? notes,
  }) {
    return RentEntry(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      month: month ?? this.month,
      openingBalance: openingBalance ?? this.openingBalance,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      extraCharges: extraCharges ?? this.extraCharges,
      extraChargesNote: extraChargesNote ?? this.extraChargesNote,
      dueDate: dueDate ?? this.dueDate,
      amountReceived: amountReceived ?? this.amountReceived,
      advanceCreditApplied: advanceCreditApplied ?? this.advanceCreditApplied,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'month': month,
      'openingBalance': openingBalance,
      'expectedAmount': expectedAmount,
      'extraCharges': extraCharges,
      'extraChargesNote': extraChargesNote,
      'dueDate': dueDate.toIso8601String(),
      'amountReceived': amountReceived,
      'advanceCreditApplied': advanceCreditApplied,
      'payments': payments.map((p) => p.toJson()).toList(),
      'status': status.name,
      'notes': notes,
    };
  }

  factory RentEntry.fromJson(Map<String, dynamic> json) {
    return RentEntry(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      propertyId: json['propertyId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      month: json['month'] as String? ?? '',
      openingBalance: (json['openingBalance'] as num?)?.toInt() ?? 0,
      expectedAmount: (json['expectedAmount'] as num?)?.toInt() ?? 0,
      extraCharges: (json['extraCharges'] as num?)?.toInt() ?? 0,
      extraChargesNote: json['extraChargesNote'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      amountReceived: (json['amountReceived'] as num?)?.toInt() ?? 0,
      advanceCreditApplied: (json['advanceCreditApplied'] as num?)?.toInt() ?? 0,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => Payment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }
}
