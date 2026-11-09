enum ExpenseCategory {
  repairs,
  propertyTax,
  electricity,
  water,
  societyCharges,
  painting,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.repairs:
        return 'Repairs & Plumbing';
      case ExpenseCategory.propertyTax:
        return 'Property Tax';
      case ExpenseCategory.electricity:
        return 'Electricity Bill';
      case ExpenseCategory.water:
        return 'Water Bill';
      case ExpenseCategory.societyCharges:
        return 'Society Maintenance';
      case ExpenseCategory.painting:
        return 'Painting & Whitewashing';
      case ExpenseCategory.other:
        return 'Other Expense';
    }
  }
}

class Expense {
  final String id;
  final String propertyId;
  final ExpenseCategory category;
  final int amount; // In integer rupees
  final DateTime date;
  final String? note;
  final String? billPhotoUrl;

  const Expense({
    required this.id,
    required this.propertyId,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.billPhotoUrl,
  });

  Expense copyWith({
    String? id,
    String? propertyId,
    ExpenseCategory? category,
    int? amount,
    DateTime? date,
    String? note,
    String? billPhotoUrl,
  }) {
    return Expense(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      billPhotoUrl: billPhotoUrl ?? this.billPhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'category': category.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'billPhotoUrl': billPhotoUrl,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      propertyId: json['propertyId'] as String? ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String?,
      billPhotoUrl: json['billPhotoUrl'] as String?,
    );
  }
}

