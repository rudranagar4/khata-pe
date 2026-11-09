enum PaymentMode {
  cash,
  bank;

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.bank:
        return 'Bank';
    }
  }

  String get displayNameHindi {
    switch (this) {
      case PaymentMode.cash:
        return 'नकद';
      case PaymentMode.bank:
        return 'बैंक';
    }
  }
}

class Payment {
  final String id;
  final String rentEntryId;
  final int amount; // In integer rupees
  final DateTime date;
  final PaymentMode mode;
  final String? referenceNo;
  final String? note;
  final String receiptNo;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.rentEntryId,
    required this.amount,
    required this.date,
    this.mode = PaymentMode.cash,
    this.referenceNo,
    this.note,
    required this.receiptNo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Payment copyWith({
    String? id,
    String? rentEntryId,
    int? amount,
    DateTime? date,
    PaymentMode? mode,
    String? referenceNo,
    String? note,
    String? receiptNo,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      rentEntryId: rentEntryId ?? this.rentEntryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      referenceNo: referenceNo ?? this.referenceNo,
      note: note ?? this.note,
      receiptNo: receiptNo ?? this.receiptNo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rentEntryId': rentEntryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'mode': mode.name,
      'referenceNo': referenceNo,
      'note': note,
      'receiptNo': receiptNo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String? ?? '',
      rentEntryId: json['rentEntryId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      mode: PaymentMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () {
          final m = json['mode'] as String?;
          if (m == 'bank' || m == 'bankTransfer' || m == 'upi' || m == 'cheque') {
            return PaymentMode.bank;
          }
          return PaymentMode.cash;
        },
      ),
      referenceNo: json['referenceNo'] as String?,
      note: json['note'] as String?,
      receiptNo: json['receiptNo'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

