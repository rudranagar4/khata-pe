import 'unit.dart';

enum PropertyType {
  building,
  room,
  pg,
  flat,
  shop,
  plot,
  godown,
  other;

  String get displayName {
    switch (this) {
      case PropertyType.building:
        return 'Building with Rooms (कमरे वाली बिल्डिंग)';
      case PropertyType.room:
        return 'Independent Room (कमरा)';
      case PropertyType.pg:
        return 'PG / Hostel / Shared Rooms';
      case PropertyType.flat:
        return 'Flat / Apartment';
      case PropertyType.shop:
        return 'Shop / Commercial';
      case PropertyType.plot:
        return 'Plot / Land';
      case PropertyType.godown:
        return 'Godown / Warehouse';
      case PropertyType.other:
        return 'Other';
    }
  }
}

class Property {
  final String id;
  final String name; // e.g. "Sharma Niwas (Building 1)"
  final PropertyType type;
  final String address;
  final String city;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;
  final List<PropertyUnit> units; // Represents rooms in this building

  Property({
    required this.id,
    required this.name,
    this.type = PropertyType.building,
    this.address = '',
    this.city = '',
    this.photoUrl,
    this.notes,
    DateTime? createdAt,
    this.units = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Room aliases & counts
  int get totalUnits => units.length;
  int get totalRooms => units.length;
  int get occupiedUnits => units.where((u) => u.isOccupied).length;
  int get occupiedRooms => units.where((u) => u.isOccupied).length;
  int get vacantUnits => units.where((u) => u.isVacant).length;
  int get vacantRooms => units.where((u) => u.isVacant).length;
  int get totalExpectedRent => units.fold(0, (sum, u) => sum + (u.isOccupied ? u.monthlyRent : 0));
  int get fullPotentialRent => units.fold(0, (sum, u) => sum + u.monthlyRent);

  Property copyWith({
    String? id,
    String? name,
    PropertyType? type,
    String? address,
    String? city,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    List<PropertyUnit>? units,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'address': address,
      'city': city,
      'photoUrl': photoUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'units': units.map((u) => u.toJson()).toList(),
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: PropertyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PropertyType.building,
      ),
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      units: (json['units'] as List<dynamic>?)
              ?.map((e) => PropertyUnit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
