/// System setting model for configuration management
class SystemSettingModel {
  final String id;
  final String key;
  final String value;
  final String valueType; // string, boolean, number, json
  final String category;
  final String? description;
  final bool isPublic;
  final bool adminEditable;
  final String? updatedBy;
  final String? updatedByName; // From join
  final DateTime? updatedAt;
  final DateTime? createdAt;

  SystemSettingModel({
    required this.id,
    required this.key,
    required this.value,
    this.valueType = 'string',
    this.category = 'general',
    this.description,
    this.isPublic = false,
    this.adminEditable = true,
    this.updatedBy,
    this.updatedByName,
    this.updatedAt,
    this.createdAt,
  });

  /// Create from JSON (Supabase response)
  factory SystemSettingModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingModel(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      valueType: json['value_type'] as String? ?? 'string',
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      adminEditable: json['admin_editable'] as bool? ?? true,
      updatedBy: json['updated_by'] as String?,
      updatedByName: json['updated_by_profile']?['full_name'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for update
  Map<String, dynamic> toUpdateJson() {
    return {
      'value': value,
      'updated_by': updatedBy,
    };
  }

  /// Copy with new value
  SystemSettingModel copyWith({
    String? id,
    String? key,
    String? value,
    String? valueType,
    String? category,
    String? description,
    bool? isPublic,
    bool? adminEditable,
    String? updatedBy,
    String? updatedByName,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return SystemSettingModel(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      category: category ?? this.category,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      adminEditable: adminEditable ?? this.adminEditable,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get typed value as bool
  bool get boolValue {
    if (valueType != 'boolean') return false;
    return value.toLowerCase() == 'true';
  }

  /// Get typed value as int
  int get intValue {
    if (valueType != 'number') return 0;
    return int.tryParse(value) ?? 0;
  }

  /// Get typed value as double
  double get doubleValue {
    if (valueType != 'number') return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  /// Get display name for key
  String get displayName {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Check if setting is editable by admin
  bool canBeEditedBy(String role) {
    if (role == 'developer') return true;
    if (role == 'admin') return adminEditable;
    return false;
  }

  @override
  String toString() {
    return 'SystemSettingModel(key: $key, value: $value, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemSettingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Well-known setting keys
class SettingKeys {
  SettingKeys._();

  static const String bannerText = 'banner_text';
  static const String bannerEnabled = 'banner_enabled';
  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceMessage = 'maintenance_message';
  static const String appVersionMinimum = 'app_version_minimum';
  static const String notificationEnabled = 'notification_enabled';
}

/// Setting categories
class SettingCategory {
  SettingCategory._();

  static const String announcement = 'announcement';
  static const String system = 'system';
  static const String notification = 'notification';
  static const String general = 'general';
}
