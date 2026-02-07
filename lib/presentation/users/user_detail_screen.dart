import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';
import '../shared/widgets/confirm_dialog.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _userRepository = UserRepository();
  final _auditLogRepository = AuditLogRepository();

  UserProfileModel? _user;
  List<AuditLogModel> _userLogs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _userRepository.getUserById(widget.userId),
        _auditLogRepository.getLogsByTarget(
          targetType: AuditTargetType.user,
          targetId: widget.userId,
          limit: 10,
        ),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as UserProfileModel?;
          _userLogs = results[1] as List<AuditLogModel>;
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

  Future<void> _changeRole(UserRole newRole) async {
    if (_user == null) return;
    final oldRole = _user!.role;

    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Change Role',
      message:
          'Change ${_user!.displayName}\'s role from ${oldRole.displayName} to ${newRole.displayName}?',
      confirmText: 'Change Role',
    );

    if (!confirm) return;

    try {
      await _userRepository.updateUserRole(widget.userId, newRole);
      await _auditLogRepository.logAction(
        action: AuditAction.userRoleChange,
        targetType: AuditTargetType.user,
        targetId: widget.userId,
        details: {
          'old_role': oldRole.value,
          'new_role': newRole.value,
        },
      );
      _loadUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change role: $e')),
        );
      }
    }
  }

  Future<void> _toggleActive() async {
    if (_user == null) return;
    final action = _user!.isActive ? 'block' : 'unblock';

    final confirm = await ConfirmDialog.show(
      context: context,
      title: '${_user!.isActive ? 'Block' : 'Unblock'} User',
      message: 'Are you sure you want to $action ${_user!.displayName}?',
      confirmText: _user!.isActive ? 'Block' : 'Unblock',
      isDangerous: _user!.isActive,
    );

    if (!confirm) return;

    try {
      await _userRepository.toggleUserActive(widget.userId, !_user!.isActive);
      await _auditLogRepository.logAction(
        action: _user!.isActive ? AuditAction.userBlock : AuditAction.userUnblock,
        targetType: AuditTargetType.user,
        targetId: widget.userId,
      );
      _loadUser();
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

    if (_isLoading) {
      return const LoadingWidget(message: 'Loading user...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load user',
        details: _error,
        onRetry: _loadUser,
      );
    }

    if (_user == null) {
      return const ErrorDisplayWidget(message: 'User not found');
    }

    final user = _user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(RouteConstants.users),
              ),
              const SizedBox(width: 8),
              Text(
                'User Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User info card
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  // Profile card
                  SizedBox(
                    width: isWide ? 350 : constraints.maxWidth,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primary,
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(
                                      user.initials,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (user.email != null)
                              Text(
                                user.email!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role.displayName,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: user.isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isActive ? 'Active' : 'Blocked',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            _DetailRow('Phone', user.phone ?? 'Not set'),
                            _DetailRow('User ID', user.id),
                            if (user.createdAt != null)
                              _DetailRow(
                                'Joined',
                                DateFormat(AppConfig.dateTimeFormat)
                                    .format(user.createdAt!),
                              ),
                            if (user.updatedAt != null)
                              _DetailRow(
                                'Last Updated',
                                DateFormat(AppConfig.dateTimeFormat)
                                    .format(user.updatedAt!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions card
                  SizedBox(
                    width: isWide
                        ? constraints.maxWidth - 350 - 24
                        : constraints.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Actions
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actions',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                if (user.canBeBlockedBy(authProvider.currentRole))
                                  _ActionButton(
                                    icon: user.isActive
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    label: user.isActive ? 'Block User' : 'Unblock User',
                                    color: user.isActive ? AppColors.error : AppColors.success,
                                    onTap: _toggleActive,
                                  ),
                                if (user.canChangeRoleBy(authProvider.currentRole)) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Change Role',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: UserRole.values
                                        .where((r) =>
                                            r != UserRole.developer &&
                                            r != user.role)
                                        .map(
                                          (role) => OutlinedButton(
                                            onPressed: () => _changeRole(role),
                                            child: Text(role.displayName),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Activity log
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity History',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                if (_userLogs.isEmpty)
                                  const Text(
                                    'No activity recorded',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  )
                                else
                                  ..._userLogs.map(
                                    (log) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(top: 6),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${log.actorDisplay} - ${log.actionDescription}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(AppConfig.dateTimeFormat)
                                                      .format(log.createdAt),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
    );
  }
}
