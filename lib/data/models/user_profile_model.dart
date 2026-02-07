import '../../core/constants/api_constants.dart';

/// User profile model for admin dashboard
class UserProfileModel {
  final String id;
  final String? fullName;
  final String? email; // From auth.users join
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.role = UserRole.user,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?, // May come from join
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role.value,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }

  /// Copy with new values
  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name (fallback to email or id)
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'User $id';
  }

  /// Get initials for avatar
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  /// Check if user can be blocked by current admin
  bool canBeBlockedBy(UserRole currentUserRole) {
    if (currentUserRole == UserRole.developer) {
      // Developer can block anyone except other developers
      return role != UserRole.developer;
    }
    if (currentUserRole == UserRole.admin) {
      // Admin can only block regular users
      return role == UserRole.user || role == UserRole.ustadz || role == UserRole.operator;
    }
    return false;
  }

  /// Check if role can be changed by current user
  bool canChangeRoleBy(UserRole currentUserRole) {
    // Only developers can change roles
    if (currentUserRole != UserRole.developer) {
      return false;
    }
    // Cannot change developer's role
    return role != UserRole.developer;
  }

  @override
  String toString() {
    return 'UserProfileModel(id: $id, fullName: $fullName, email: $email, role: ${role.value}, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
