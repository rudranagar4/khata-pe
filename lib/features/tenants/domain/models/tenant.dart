class Tenant {
  final String id;
  final String name;
  final String phone;
  final String? altPhone;
  final String? email;
  final String? idProofType; // Aadhaar, PAN, Voter ID, etc.
  final String? idProofNumber;
  final List<String> documentUrls;
  final String propertyId;
  final String unitId;
  final DateTime moveInDate;
  final DateTime? agreementEndDate;
  final int monthlyRent;
  final int rentDueDay; // 1 to 31
  final int securityDeposit;
  final bool isActive;
  final DateTime? moveOutDate;
  final String? notes;

  const Tenant({
    required this.id,
    required this.name,
    required this.phone,
    this.altPhone,
    this.email,
    this.idProofType,
    this.idProofNumber,
    this.documentUrls = const [],
    required this.propertyId,
    required this.unitId,
    required this.moveInDate,
    this.agreementEndDate,
    required this.monthlyRent,
    this.rentDueDay = 5,
    this.securityDeposit = 0,
    this.isActive = true,
    this.moveOutDate,
    this.notes,
  });

  /// Check if agreement is expiring within given number of days
  bool isAgreementExpiringWithin(int days) {
    if (agreementEndDate == null || !isActive) return false;
    final now = DateTime.now();
    final difference = agreementEndDate!.difference(now).inDays;
    return difference >= 0 && difference <= days;
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? phone,
    String? altPhone,
    String? email,
    String? idProofType,
    String? idProofNumber,
    List<String>? documentUrls,
    String? propertyId,
    String? unitId,
    DateTime? moveInDate,
    DateTime? agreementEndDate,
    int? monthlyRent,
    int? rentDueDay,
    int? securityDeposit,
    bool? isActive,
    DateTime? moveOutDate,
    String? notes,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      email: email ?? this.email,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      documentUrls: documentUrls ?? this.documentUrls,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      moveInDate: moveInDate ?? this.moveInDate,
      agreementEndDate: agreementEndDate ?? this.agreementEndDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      rentDueDay: rentDueDay ?? this.rentDueDay,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      isActive: isActive ?? this.isActive,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'altPhone': altPhone,
      'email': email,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'documentUrls': documentUrls,
      'propertyId': propertyId,
      'unitId': unitId,
      'moveInDate': moveInDate.toIso8601String(),
      'agreementEndDate': agreementEndDate?.toIso8601String(),
      'monthlyRent': monthlyRent,
      'rentDueDay': rentDueDay,
      'securityDeposit': securityDeposit,
      'isActive': isActive,
      'moveOutDate': moveOutDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      altPhone: json['altPhone'] as String?,
      email: json['email'] as String?,
      idProofType: json['idProofType'] as String?,
      idProofNumber: json['idProofNumber'] as String?,
      documentUrls: (json['documentUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      propertyId: json['propertyId'] as String? ?? '',
      unitId: json['unitId'] as String? ?? '',
      moveInDate: json['moveInDate'] != null
          ? DateTime.tryParse(json['moveInDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      agreementEndDate: json['agreementEndDate'] != null
          ? DateTime.tryParse(json['agreementEndDate'] as String)
          : null,
      monthlyRent: (json['monthlyRent'] as num?)?.toInt() ?? 0,
      rentDueDay: (json['rentDueDay'] as num?)?.toInt() ?? 5,
      securityDeposit: (json['securityDeposit'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      moveOutDate: json['moveOutDate'] != null
          ? DateTime.tryParse(json['moveOutDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

