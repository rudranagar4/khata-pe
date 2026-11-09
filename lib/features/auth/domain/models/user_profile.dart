class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String language;
  final String? upiId;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.language = 'en',
    this.upiId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? language,
    String? upiId,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      upiId: upiId ?? this.upiId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'language': language,
      'upiId': upiId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      upiId: json['upiId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

