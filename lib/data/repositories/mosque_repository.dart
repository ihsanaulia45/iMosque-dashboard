import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/mosque_model.dart';

class MosqueRepository {
  final SupabaseClient _client;

  MosqueRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<MosqueModel>> getMosques({
    String? search,
    bool? isVerified,
    int page = 1,
    int pageSize = 10,
  }) async {
    var query = _client.from(ApiConstants.mosquesTable).select();

    if (isVerified != null) {
      query = query.eq('is_verified', isVerified);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,address.ilike.%$search%,city.ilike.%$search%');
    }

    final offset = (page - 1) * pageSize;
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1);

    return (response as List)
        .map((json) => MosqueModel.fromJson(json))
        .toList();
  }

  Future<int> getMosquesCount({
    String? search,
    bool? isVerified,
  }) async {
    var query = _client.from(ApiConstants.mosquesTable).select('id');

    if (isVerified != null) {
      query = query.eq('is_verified', isVerified);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,address.ilike.%$search%,city.ilike.%$search%');
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  Future<MosqueModel?> getMosqueById(String mosqueId) async {
    final response = await _client
        .from(ApiConstants.mosquesTable)
        .select()
        .eq('id', mosqueId)
        .maybeSingle();

    if (response == null) return null;
    return MosqueModel.fromJson(response);
  }

  Future<void> createMosque(MosqueModel mosque) async {
    await _client
        .from(ApiConstants.mosquesTable)
        .insert(mosque.toInsertJson());
  }

  Future<void> updateMosque(String mosqueId, Map<String, dynamic> data) async {
    await _client
        .from(ApiConstants.mosquesTable)
        .update(data)
        .eq('id', mosqueId);
  }

  Future<void> setVerified(String mosqueId, bool isVerified) async {
    await _client
        .from(ApiConstants.mosquesTable)
        .update({'is_verified': isVerified}).eq('id', mosqueId);
  }
}
