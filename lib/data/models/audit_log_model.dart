/// Audit log model for tracking admin/developer actions
class AuditLogModel {
  final String id;
  final String actorId;
  final String actorRole;
  final String? actorName; // From join with profiles
  final String action;
  final String targetType;
  final String? targetId;
  final String? targetName; // From join (optional)
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.actorId,
    required this.actorRole,
    this.actorName,
    required this.action,
    required this.targetType,
    this.targetId,
    this.targetName,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      actorRole: json['actor_role'] as String,
      actorName: json['actor_profile']?['full_name'] as String?,
      action: json['action'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String?,
      targetName: _extractTargetName(json),
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Extract target name from nested join data
  static String? _extractTargetName(Map<String, dynamic> json) {
    // Check for user target
    if (json['target_profile'] != null) {
      return json['target_profile']['full_name'] as String?;
    }
    // Check for mosque target
    if (json['target_mosque'] != null) {
      return json['target_mosque']['name'] as String?;
    }
    // Check for setting target
    if (json['target_setting'] != null) {
      return json['target_setting']['key'] as String?;
    }
    return null;
  }

  /// Convert to JSON for insert
  Map<String, dynamic> toInsertJson() {
    return {
      'actor_id': actorId,
      'actor_role': actorRole,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details,
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  /// Get human-readable action description
  String get actionDescription {
    switch (action) {
      case 'user.login':
        return 'Logged in';
      case 'user.logout':
        return 'Logged out';
      case 'user.block':
        return 'Blocked user';
      case 'user.unblock':
        return 'Unblocked user';
      case 'user.role_change':
        final oldRole = details?['old_role'] ?? 'unknown';
        final newRole = details?['new_role'] ?? 'unknown';
        return 'Changed role from $oldRole to $newRole';
      case 'mosque.create':
        return 'Created mosque';
      case 'mosque.update':
        return 'Updated mosque';
      case 'mosque.verify':
        return 'Verified mosque';
      case 'mosque.reject':
        return 'Rejected mosque';
      case 'mosque.activate':
        return 'Activated mosque';
      case 'mosque.deactivate':
        return 'Deactivated mosque';
      case 'setting.update':
        final key = details?['key'] ?? 'setting';
        return 'Updated $key';
      default:
        return action;
    }
  }

  /// Get target display name
  String get targetDisplay {
    if (targetName != null && targetName!.isNotEmpty) {
      return targetName!;
    }
    if (targetId != null) {
      return '$targetType #${targetId!.substring(0, 8)}...';
    }
    return targetType;
  }

  /// Get actor display name
  String get actorDisplay {
    if (actorName != null && actorName!.isNotEmpty) {
      return actorName!;
    }
    return 'User ${actorId.substring(0, 8)}...';
  }

  @override
  String toString() {
    return 'AuditLogModel(id: $id, action: $action, actor: $actorId, target: $targetId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLogModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
