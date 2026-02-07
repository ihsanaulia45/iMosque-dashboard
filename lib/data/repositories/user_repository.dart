import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<UserProfileModel>> getUsers({
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 10,
  }) async {
    var query = _client.from(ApiConstants.profilesTable).select();

    if (role != null) {
      query = query.eq('role', role);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,phone.ilike.%$search%');
    }

    final offset = (page - 1) * pageSize;
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return (response as List)
        .map((json) => UserProfileModel.fromJson(json))
        .toList();
  }

  Future<int> getUsersCount({
    String? search,
    String? role,
    bool? isActive,
  }) async {
    var query = _client.from(ApiConstants.profilesTable).select('id');

    if (role != null) {
      query = query.eq('role', role);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,phone.ilike.%$search%');
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  Future<UserProfileModel?> getUserById(String userId) async {
    final response = await _client
        .from(ApiConstants.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfileModel.fromJson(response);
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _client
        .from(ApiConstants.profilesTable)
        .update({'role': newRole.value}).eq('id', userId);
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    await _client
        .from(ApiConstants.profilesTable)
        .update({'is_active': isActive}).eq('id', userId);
  }
}
