enum UnitStatus {
  occupied,
  vacant,
}

class PropertyUnit {
  final String id;
  final String propertyId;
  final String unitName; // e.g. "Room 101", "Room 102", "Room 1"
  final int monthlyRent; // In integer rupees - Rent collected for this room
  final int securityDeposit; // In integer rupees
  final UnitStatus status;
  final double? areaSqFt;
  final String? floor; // e.g. "Ground Floor", "1st Floor", "2nd Floor"
  final String? roomType; // e.g. "Single Room", "Double Sharing", "1RK", "Attached Bath"
  final String? meterNumber; // Sub-meter for electricity
  final String? notes;

  const PropertyUnit({
    required this.id,
    required this.propertyId,
    required this.unitName,
    required this.monthlyRent,
    this.securityDeposit = 0,
    this.status = UnitStatus.vacant,
    this.areaSqFt,
    this.floor,
    this.roomType,
    this.meterNumber,
    this.notes,
  });

  bool get isOccupied => status == UnitStatus.occupied;
  bool get isVacant => status == UnitStatus.vacant;

  /// Returns clean room display name like "Room 101"
  String get roomDisplayName {
    final name = unitName.trim();
    if (name.toLowerCase().startsWith('room') ||
        name.toLowerCase().startsWith('कमरा') ||
        name.toLowerCase().startsWith('shop')) {
      return name;
    }
    return 'Room $name';
  }

  PropertyUnit copyWith({
    String? id,
    String? propertyId,
    String? unitName,
    int? monthlyRent,
    int? securityDeposit,
    UnitStatus? status,
    double? areaSqFt,
    String? floor,
    String? roomType,
    String? meterNumber,
    String? notes,
  }) {
    return PropertyUnit(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitName: unitName ?? this.unitName,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      areaSqFt: areaSqFt ?? this.areaSqFt,
      floor: floor ?? this.floor,
      roomType: roomType ?? this.roomType,
      meterNumber: meterNumber ?? this.meterNumber,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitName': unitName,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'status': status.name,
      'areaSqFt': areaSqFt,
      'floor': floor,
      'roomType': roomType,
      'meterNumber': meterNumber,
      'notes': notes,
    };
  }

  factory PropertyUnit.fromJson(Map<String, dynamic> json) {
    return PropertyUnit(
      id: json['id'] as String? ?? '',
      propertyId: json['propertyId'] as String? ?? '',
      unitName: json['unitName'] as String? ?? '',
      monthlyRent: (json['monthlyRent'] as num?)?.toInt() ?? 0,
      securityDeposit: (json['securityDeposit'] as num?)?.toInt() ?? 0,
      status: UnitStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UnitStatus.vacant,
      ),
      areaSqFt: (json['areaSqFt'] as num?)?.toDouble(),
      floor: json['floor'] as String?,
      roomType: json['roomType'] as String?,
      meterNumber: json['meterNumber'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
