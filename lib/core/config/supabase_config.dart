import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  static String? _supabaseUrl;
  static String? _supabaseAnonKey;

  /// Get Supabase URL
  static String get supabaseUrl {
    if (_supabaseUrl == null) {
      throw Exception('SupabaseConfig not initialized. Call init() first.');
    }
    return _supabaseUrl!;
  }

  /// Get Supabase Anon Key
  static String get supabaseAnonKey {
    if (_supabaseAnonKey == null) {
      throw Exception('SupabaseConfig not initialized. Call init() first.');
    }
    return _supabaseAnonKey!;
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Get current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Initialize Supabase
  static Future<void> init() async {
    // Load environment configuration
    final String envJson = await rootBundle.loadString('assets/env.json');
    final Map<String, dynamic> env = json.decode(envJson);

    _supabaseUrl = env['SUPABASE_URL'];
    _supabaseAnonKey = env['SUPABASE_ANON_KEY'];

    if (_supabaseUrl == null || _supabaseAnonKey == null) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found in env.json');
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: _supabaseUrl!,
      anonKey: _supabaseAnonKey!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }
}
