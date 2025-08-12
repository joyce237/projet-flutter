class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'user' or 'pharmacist'
  final String? pharmacyId; // Pour les pharmaciens
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pharmacyId,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      pharmacyId: map['pharmacyId'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt']) 
          : null,
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'pharmacyId': pharmacyId,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? pharmacyId,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get isPharmacist => role == 'pharmacist';
  bool get isUser => role == 'user';
  
  String get displayName => name.isNotEmpty ? name : email;
  String get initials {
    if (name.isEmpty) return email.substring(0, 1).toUpperCase();
    final names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}