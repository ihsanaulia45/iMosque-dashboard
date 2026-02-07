import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/repositories/audit_log_repository.dart';
import '../../theme/app_colors.dart';
import '../shared/widgets/loading_widget.dart';
import '../shared/widgets/error_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auditLogRepository = AuditLogRepository();

  bool _isLoading = true;
  String? _error;

  int _totalUsers = 0;
  int _totalMosques = 0;
  int _pendingMosques = 0;
  int _verifiedMosques = 0;
  List<AuditLogModel> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseConfig.client;

      // Fetch counts in parallel
      final countResults = await Future.wait([
        client.from(ApiConstants.profilesTable).select('id').count(CountOption.exact),
        client.from(ApiConstants.mosquesTable).select('id').count(CountOption.exact),
        client.from(ApiConstants.mosquesTable).select('id').eq('is_verified', false).count(CountOption.exact),
        client.from(ApiConstants.mosquesTable).select('id').eq('is_verified', true).count(CountOption.exact),
      ]);

      // Try to fetch recent activity (audit_logs table may not exist yet)
      List<AuditLogModel> recentActivity = [];
      try {
        recentActivity = await _auditLogRepository.getRecentActivity(limit: 8);
      } catch (_) {
        // audit_logs table may not exist yet - silently ignore
      }

      if (mounted) {
        setState(() {
          _totalUsers = countResults[0].count;
          _totalMosques = countResults[1].count;
          _pendingMosques = countResults[2].count;
          _verifiedMosques = countResults[3].count;
          _recentActivity = recentActivity;
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    authProvider.updateLastActivity();

    if (_isLoading) {
      return const LoadingWidget(message: 'Loading dashboard...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load dashboard',
        details: _error,
        onRetry: _loadDashboardData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome back, ${authProvider.currentProfile?.displayName ?? 'Admin'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening with your mosques today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                final cardWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                        crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(
                      width: cardWidth,
                      title: 'Total Users',
                      value: _totalUsers.toString(),
                      icon: Icons.people,
                      color: AppColors.info,
                      onTap: () => context.go(RouteConstants.users),
                    ),
                    _StatCard(
                      width: cardWidth,
                      title: 'Total Mosques',
                      value: _totalMosques.toString(),
                      icon: Icons.mosque,
                      color: AppColors.primary,
                      onTap: () => context.go(RouteConstants.mosques),
                    ),
                    _StatCard(
                      width: cardWidth,
                      title: 'Pending Verification',
                      value: _pendingMosques.toString(),
                      icon: Icons.pending_actions,
                      color: AppColors.warning,
                      onTap: () => context.go(RouteConstants.mosques),
                    ),
                    _StatCard(
                      width: cardWidth,
                      title: 'Verified Mosques',
                      value: _verifiedMosques.toString(),
                      icon: Icons.verified,
                      color: AppColors.success,
                      onTap: () => context.go(RouteConstants.mosques),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Recent activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go(RouteConstants.auditLogs),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_recentActivity.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final log = _recentActivity[index];
                    return _ActivityTile(log: log);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AuditLogModel log;

  const _ActivityTile({required this.log});

  IconData _getActionIcon() {
    if (log.action.startsWith('user.')) {
      return Icons.person;
    }
    if (log.action.startsWith('mosque.')) {
      return Icons.mosque;
    }
    if (log.action.startsWith('setting.')) {
      return Icons.settings;
    }
    return Icons.info_outline;
  }

  Color _getActionColor() {
    if (log.action.contains('block') || log.action.contains('reject') || log.action.contains('deactivate')) {
      return AppColors.error;
    }
    if (log.action.contains('verify') || log.action.contains('activate') || log.action.contains('create')) {
      return AppColors.success;
    }
    if (log.action.contains('login') || log.action.contains('logout')) {
      return AppColors.info;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(log.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor().withOpacity(0.1),
        child: Icon(_getActionIcon(), color: _getActionColor(), size: 20),
      ),
      title: Text(
        log.actionDescription,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${log.actorDisplay} \u2022 ${log.targetDisplay}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Text(
        timeAgo,
        style: const TextStyle(fontSize: 12, color: AppColors.textDisabled),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dateTime);
  }
}
