import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _auditLogRepository = AuditLogRepository();

  List<AuditLogModel> _logs = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  String? _actionFilter;
  String? _targetTypeFilter;
  bool _isLoading = true;
  String? _error;
  bool _tableNotFound = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tableNotFound = false;
    });

    try {
      final results = await Future.wait([
        _auditLogRepository.getLogs(
          action: _actionFilter,
          targetType: _targetTypeFilter,
          page: _currentPage,
          pageSize: _pageSize,
        ),
        _auditLogRepository.getLogsCount(
          action: _actionFilter,
          targetType: _targetTypeFilter,
        ),
      ]);

      if (mounted) {
        setState(() {
          _logs = results[0] as List<AuditLogModel>;
          _totalCount = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('audit_logs') &&
            (errorStr.contains('does not exist') ||
             errorStr.contains('Could not find') ||
             errorStr.contains('schema cache') ||
             errorStr.contains('PGRST205') ||
             errorStr.contains('relation') ||
             errorStr.contains('42P01'))) {
          setState(() {
            _tableNotFound = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = errorStr;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();
    final totalPages = (_totalCount / _pageSize).ceil();

    // Show friendly message when table doesn't exist
    if (_tableNotFound) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audit Logs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Audit Logs Table Not Available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The audit_logs table has not been created yet in the database.\n'
                      'Please run the SQL migration to create the required tables.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadLogs,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit Logs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_totalCount log entries',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),

          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _targetTypeFilter,
                  decoration: const InputDecoration(
                    labelText: 'Target Type',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'mosque', child: Text('Mosque')),
                    DropdownMenuItem(value: 'setting', child: Text('Setting')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _targetTypeFilter = value;
                      _actionFilter = null;
                      _currentPage = 1;
                    });
                    _loadLogs();
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _actionFilter,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Actions')),
                    const DropdownMenuItem(
                        value: AuditAction.userLogin, child: Text('User Login')),
                    const DropdownMenuItem(
                        value: AuditAction.userLogout, child: Text('User Logout')),
                    const DropdownMenuItem(
                        value: AuditAction.userBlock, child: Text('User Block')),
                    const DropdownMenuItem(
                        value: AuditAction.userUnblock, child: Text('User Unblock')),
                    const DropdownMenuItem(
                        value: AuditAction.userRoleChange,
                        child: Text('Role Change')),
                    const DropdownMenuItem(
                        value: AuditAction.mosqueCreate,
                        child: Text('Mosque Create')),
                    const DropdownMenuItem(
                        value: AuditAction.mosqueUpdate,
                        child: Text('Mosque Update')),
                    const DropdownMenuItem(
                        value: AuditAction.mosqueVerify,
                        child: Text('Mosque Verify')),
                    const DropdownMenuItem(
                        value: AuditAction.mosqueReject,
                        child: Text('Mosque Reject')),
                    const DropdownMenuItem(
                        value: AuditAction.settingUpdate,
                        child: Text('Setting Update')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _actionFilter = value;
                      _currentPage = 1;
                    });
                    _loadLogs();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadLogs,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logs table
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading audit logs...')
                : _error != null
                    ? ErrorDisplayWidget(
                        message: 'Failed to load audit logs',
                        details: _error,
                        onRetry: _loadLogs,
                      )
                    : _logs.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No audit logs found',
                            icon: Icons.history,
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
                                          DataColumn(label: Text('Timestamp')),
                                          DataColumn(label: Text('Actor')),
                                          DataColumn(label: Text('Role')),
                                          DataColumn(label: Text('Action')),
                                          DataColumn(label: Text('Target')),
                                          DataColumn(label: Text('Details')),
                                        ],
                                        rows: _logs.map((log) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(
                                                DateFormat(AppConfig.dateTimeFormat)
                                                    .format(log.createdAt),
                                                style: const TextStyle(fontSize: 13),
                                              )),
                                              DataCell(Text(
                                                log.actorDisplay,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              )),
                                              DataCell(Text(
                                                log.actorRole,
                                                style: const TextStyle(fontSize: 13),
                                              )),
                                              DataCell(
                                                _ActionBadge(action: log.action),
                                              ),
                                              DataCell(Text(
                                                log.targetDisplay,
                                                style: const TextStyle(fontSize: 13),
                                              )),
                                              DataCell(
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    log.actionDescription,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
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
                                                  _loadLogs();
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < totalPages
                                              ? () {
                                                  setState(() => _currentPage++);
                                                  _loadLogs();
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

class _ActionBadge extends StatelessWidget {
  final String action;
  const _ActionBadge({required this.action});

  Color get _color {
    if (action.contains('block') || action.contains('reject') || action.contains('deactivate')) {
      return AppColors.error;
    }
    if (action.contains('verify') || action.contains('activate') || action.contains('create') || action.contains('unblock')) {
      return AppColors.success;
    }
    if (action.contains('login') || action.contains('logout')) {
      return AppColors.info;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
