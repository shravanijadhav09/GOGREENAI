enum UserRole {
  customer,
  nurseryOwner,
  superAdmin;

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'NURSERY_OWNER':
        return UserRole.nurseryOwner;
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'CUSTOMER':
      default:
        return UserRole.customer;
    }
  }

  String toServerString() {
    switch (this) {
      case UserRole.nurseryOwner:
        return 'NURSERY_OWNER';
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.nurseryOwner:
        return 'Nursery Owner';
      case UserRole.superAdmin:
        return 'Administrator';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.trim().isNotEmpty);
    if (parts.isEmpty) return email.split('@').first;
    return parts.join(' ');
  }

  bool get isOwner => role == UserRole.nurseryOwner;
  bool get isCustomer => role == UserRole.customer;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toServerString(),
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
