import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/audit_log_model.dart';

/// Repository for audit log operations
class AuditLogRepository {
  final SupabaseClient _client;

  AuditLogRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// Log an action
  Future<void> logAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      // Get current user profile for role
      final profileResponse = await _client
          .from(ApiConstants.profilesTable)
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();

      final actorRole = profileResponse?['role'] ?? 'user';

      await _client.from(ApiConstants.auditLogsTable).insert({
        'actor_id': currentUser.id,
        'actor_role': actorRole,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
        'ip_address': ipAddress,
        'user_agent': kIsWeb ? 'Web Browser' : 'Unknown',
      });
    } catch (e) {
      debugPrint('Error logging action: $e');
      // Don't throw - audit logging should not break main flow
    }
  }

  /// Get audit logs with filters
  Future<List<AuditLogModel>> getLogs({
    String? actorId,
    String? action,
    String? targetType,
    String? targetId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 10,
  }) async {
    var query = _client
        .from(ApiConstants.auditLogsTable)
        .select('''
          *,
          actor_profile:profiles!audit_logs_actor_id_fkey(full_name)
        ''');

    // Apply filters
    if (actorId != null) {
      query = query.eq('actor_id', actorId);
    }
    if (action != null) {
      query = query.eq('action', action);
    }
    if (targetType != null) {
      query = query.eq('target_type', targetType);
    }
    if (targetId != null) {
      query = query.eq('target_id', targetId);
    }
    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query = query.lte('created_at', dateTo.toIso8601String());
    }

    // Pagination
    final offset = (page - 1) * pageSize;
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return (response as List)
        .map((json) => AuditLogModel.fromJson(json))
        .toList();
  }

  /// Get total count of logs with filters
  Future<int> getLogsCount({
    String? actorId,
    String? action,
    String? targetType,
    String? targetId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var query = _client
        .from(ApiConstants.auditLogsTable)
        .select('id');

    // Apply filters
    if (actorId != null) {
      query = query.eq('actor_id', actorId);
    }
    if (action != null) {
      query = query.eq('action', action);
    }
    if (targetType != null) {
      query = query.eq('target_type', targetType);
    }
    if (targetId != null) {
      query = query.eq('target_id', targetId);
    }
    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query = query.lte('created_at', dateTo.toIso8601String());
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  /// Get recent activity for dashboard
  Future<List<AuditLogModel>> getRecentActivity({int limit = 10}) async {
    final response = await _client
        .from(ApiConstants.auditLogsTable)
        .select('''
          *,
          actor_profile:profiles!audit_logs_actor_id_fkey(full_name)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => AuditLogModel.fromJson(json))
        .toList();
  }

  /// Get logs by target
  Future<List<AuditLogModel>> getLogsByTarget({
    required String targetType,
    required String targetId,
    int limit = 20,
  }) async {
    final response = await _client
        .from(ApiConstants.auditLogsTable)
        .select('''
          *,
          actor_profile:profiles!audit_logs_actor_id_fkey(full_name)
        ''')
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => AuditLogModel.fromJson(json))
        .toList();
  }
}
