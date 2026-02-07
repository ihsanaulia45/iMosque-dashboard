import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';
import '../shared/widgets/confirm_dialog.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _userRepository = UserRepository();
  final _auditLogRepository = AuditLogRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<UserProfileModel> _users = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;
  String? _roleFilter;
  bool? _activeFilter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: AppConfig.searchDebounceMs),
      () {
        _currentPage = 1;
        _loadUsers();
      },
    );
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final results = await Future.wait([
        _userRepository.getUsers(
          search: search.isEmpty ? null : search,
          role: _roleFilter,
          isActive: _activeFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
        _userRepository.getUsersCount(
          search: search.isEmpty ? null : search,
          role: _roleFilter,
          isActive: _activeFilter,
        ),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<UserProfileModel>;
          _totalCount = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleUserActive(UserProfileModel user) async {
    final action = user.isActive ? 'block' : 'unblock';
    final confirm = await ConfirmDialog.show(
      context: context,
      title: '${user.isActive ? 'Block' : 'Unblock'} User',
      message:
          'Are you sure you want to $action ${user.displayName}?',
      confirmText: user.isActive ? 'Block' : 'Unblock',
      isDangerous: user.isActive,
    );

    if (!confirm) return;

    try {
      await _userRepository.toggleUserActive(user.id, !user.isActive);
      await _auditLogRepository.logAction(
        action: user.isActive ? AuditAction.userBlock : AuditAction.userUnblock,
        targetType: AuditTargetType.user,
        targetId: user.id,
      );
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();
    final totalPages = (_totalCount / _pageSize).ceil();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Users',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_totalCount users total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),

          // Filters row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  value: _roleFilter,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Roles')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'ustadz', child: Text('Ustadz')),
                    DropdownMenuItem(value: 'operator', child: Text('Operator')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'developer', child: Text('Developer')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _roleFilter = value;
                      _currentPage = 1;
                    });
                    _loadUsers();
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<bool?>(
                  value: _activeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: true, child: Text('Active')),
                    DropdownMenuItem(value: false, child: Text('Blocked')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _activeFilter = value;
                      _currentPage = 1;
                    });
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Data table
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading users...')
                : _error != null
                    ? ErrorDisplayWidget(
                        message: 'Failed to load users',
                        details: _error,
                        onRetry: _loadUsers,
                      )
                    : _users.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No users found',
                            icon: Icons.people_outline,
                          )
                        : Card(
                            margin: EdgeInsets.zero,
                            child: Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('User')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Phone')),
                                          DataColumn(label: Text('Status')),
                                          DataColumn(label: Text('Joined')),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: _users.map((user) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                InkWell(
                                                  onTap: () => context.go(
                                                    RouteConstants.getUserDetailPath(user.id),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor: AppColors.primary,
                                                        backgroundImage: user.avatarUrl != null
                                                            ? NetworkImage(user.avatarUrl!)
                                                            : null,
                                                        child: user.avatarUrl == null
                                                            ? Text(
                                                                user.initials,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            user.displayName,
                                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          if (user.email != null)
                                                            Text(
                                                              user.email!,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors.textSecondary,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(_RoleBadge(role: user.role)),
                                              DataCell(Text(user.phone ?? '-')),
                                              DataCell(_StatusBadge(isActive: user.isActive)),
                                              DataCell(Text(
                                                user.createdAt != null
                                                    ? DateFormat(AppConfig.dateFormat).format(user.createdAt!)
                                                    : '-',
                                              )),
                                              DataCell(
                                                user.canBeBlockedBy(authProvider.currentRole)
                                                    ? IconButton(
                                                        icon: Icon(
                                                          user.isActive
                                                              ? Icons.block
                                                              : Icons.check_circle_outline,
                                                          color: user.isActive
                                                              ? AppColors.error
                                                              : AppColors.success,
                                                          size: 20,
                                                        ),
                                                        tooltip: user.isActive ? 'Block' : 'Unblock',
                                                        onPressed: () => _toggleUserActive(user),
                                                      )
                                                    : const SizedBox.shrink(),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),

                                // Pagination
                                if (totalPages > 1)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Page $_currentPage of $totalPages',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () {
                                                  setState(() => _currentPage--);
                                                  _loadUsers();
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < totalPages
                                              ? () {
                                                  setState(() => _currentPage++);
                                                  _loadUsers();
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case UserRole.developer:
        return AppColors.info;
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.operator:
        return AppColors.warning;
      case UserRole.ustadz:
        return AppColors.accentGold;
      case UserRole.user:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Active' : 'Blocked',
          style: TextStyle(
            fontSize: 13,
            color: isActive ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}
