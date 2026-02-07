import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_profile_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/audit_log_repository.dart';

/// Authentication state provider
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final AuditLogRepository _auditLogRepository;

  // State
  User? _currentUser;
  UserProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastActivity;
  Timer? _sessionTimer;
  bool _showSessionWarning = false;

  AuthProvider({
    AuthRepository? authRepository,
    AuditLogRepository? auditLogRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository() {
    _initializeAuth();
  }

  // Getters
  User? get currentUser => _currentUser;
  UserProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showSessionWarning => _showSessionWarning;

  bool get isAuthenticated => _currentUser != null && _currentProfile != null;
  bool get isAdmin => _currentProfile?.role == UserRole.admin;
  bool get isDeveloper => _currentProfile?.role == UserRole.developer;
  bool get hasDashboardAccess =>
      _currentProfile?.role.hasDashboardAccess ?? false;

  UserRole get currentRole => _currentProfile?.role ?? UserRole.user;

  /// Initialize auth state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check existing session
      final session = SupabaseConfig.currentSession;
      if (session != null) {
        _currentUser = SupabaseConfig.currentUser;
        if (_currentUser != null) {
          await _loadProfile();
          if (hasDashboardAccess) {
            _startSessionTimer();
            updateLastActivity();
          }
        }
      }

      // Listen to auth state changes
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _currentUser = session.user;
          _loadProfile();
        } else if (event == AuthChangeEvent.signedOut) {
          _clearState();
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          _currentUser = session?.user;
        }
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Authenticate
      final response = await _authRepository.signIn(email, password);
      _currentUser = response.user;

      if (_currentUser == null) {
        throw Exception('Authentication failed');
      }

      // Load profile
      await _loadProfile();

      // Check if user has dashboard access
      if (!hasDashboardAccess) {
        await signOut();
        _error = 'Access denied. You do not have permission to access the admin dashboard.';
        notifyListeners();
        return false;
      }

      // Log successful login
      await _auditLogRepository.logAction(
        action: AuditAction.userLogin,
        targetType: AuditTargetType.user,
        targetId: _currentUser!.id,
      );

      // Start session timer
      _startSessionTimer();
      updateLastActivity();

      return true;
    } on AuthException catch (e) {
      _error = _getAuthErrorMessage(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile from database
  Future<void> _loadProfile() async {
    if (_currentUser == null) return;

    try {
      _currentProfile = await _authRepository.getProfile(_currentUser!.id);

      // Fetch email from auth user
      if (_currentProfile != null && _currentUser!.email != null) {
        _currentProfile = _currentProfile!.copyWith(email: _currentUser!.email);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _error = 'Failed to load user profile';
    }
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Log logout before signing out
      if (_currentUser != null && hasDashboardAccess) {
        await _auditLogRepository.logAction(
          action: AuditAction.userLogout,
          targetType: AuditTargetType.user,
          targetId: _currentUser!.id,
        );
      }

      await _authRepository.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _clearState();
    }
  }

  /// Clear all state
  void _clearState() {
    _currentUser = null;
    _currentProfile = null;
    _lastActivity = null;
    _showSessionWarning = false;
    _stopSessionTimer();
    notifyListeners();
  }

  /// Update last activity timestamp
  void updateLastActivity() {
    _lastActivity = DateTime.now();
    if (_showSessionWarning) {
      _showSessionWarning = false;
      notifyListeners();
    }
  }

  /// Start session timeout timer
  void _startSessionTimer() {
    _stopSessionTimer();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionTimeout(),
    );
  }

  /// Stop session timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Check session timeout
  void _checkSessionTimeout() {
    if (_lastActivity == null || !isAuthenticated) return;

    final now = DateTime.now();
    final idleMinutes = now.difference(_lastActivity!).inMinutes;

    final warningMinutes =
        AppConfig.sessionTimeoutMinutes - AppConfig.sessionWarningMinutes;

    if (idleMinutes >= AppConfig.sessionTimeoutMinutes) {
      // Session expired
      signOut();
    } else if (idleMinutes >= warningMinutes && !_showSessionWarning) {
      // Show warning
      _showSessionWarning = true;
      notifyListeners();
    }
  }

  /// Dismiss session warning and continue
  void dismissSessionWarning() {
    _showSessionWarning = false;
    updateLastActivity();
  }

  /// Get human-readable auth error message
  String _getAuthErrorMessage(AuthException e) {
    if (e.message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (e.message.contains('Email not confirmed')) {
      return 'Please verify your email address';
    }
    if (e.message.contains('Too many requests')) {
      return 'Too many login attempts. Please try again later';
    }
    return e.message;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
